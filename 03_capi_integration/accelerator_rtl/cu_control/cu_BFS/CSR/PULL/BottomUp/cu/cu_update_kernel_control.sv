// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_update_kernel_control.sv
// Create : 2019-09-26 15:19:17
// Revise : 2019-11-03 12:38:39
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_update_kernel_control #(
	parameter CU_ID_X    = 1,
	parameter CU_ID_Y    = 1,
	parameter BREAK_HOLD = 5
) (
	input  logic                          clock                      , // Clock
	input  logic                          rstn_in                    ,
	input  logic                          enabled_in                 ,
	input  ResponseBufferLine             write_response_in          ,
	input  BufferStatus                   write_buffer_status        ,
	input  EdgeDataRead                   edge_data                  ,
	input  BufferStatus                   data_buffer_status         ,
	input  logic                          edge_data_write_bus_grant  ,
	output logic                          edge_data_write_bus_request,
	output logic                          edge_data_request          ,
	output EdgeDataWrite                  edge_data_write_out        ,
	input  VertexInterface                vertex_job                 ,
	output logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp_out,
	output logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum_out,
	output logic                          break_S_out
);

	logic              rstn                               ;
	EdgeDataRead       edge_data_latched                  ;
	EdgeDataWrite      edge_data_update                   ;
	EdgeDataWrite      edge_data_update_latch             ;
	logic              enabled                            ;
	VertexInterface    vertex_job_latched                 ;
	BufferStatus       edge_data_write_buffer_status      ;
	EdgeDataWrite      edge_data_write_buffer             ;
	logic              edge_data_write_bus_grant_latched  ;
	logic              edge_data_write_bus_request_latched;
	BufferStatus       data_buffer_status_latch           ;
	logic              edge_data_write_bus_request_pop    ;
	ResponseBufferLine write_response_in_latched          ;
	BufferStatus       write_buffer_status_latched        ;

	logic [0:(VERTEX_SIZE_BITS-1)] vertex_num_counter_resp   ;
	logic [  0:(EDGE_SIZE_BITS-1)] edge_data_counter_accum   ;
	logic [  0:(EDGE_SIZE_BITS-1)] inverse_out_degree_counter;
	logic [        0:BREAK_HOLD-1] break_S1                  ;


////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn <= 0;
		end else begin
			rstn <= rstn_in;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_out.valid   <= 0;
			edge_data_request           <= 0;
			vertex_num_counter_resp_out <= 0;
			edge_data_counter_accum_out <= 0;
			break_S_out                 <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_out.valid   <= edge_data_write_buffer.valid;
				edge_data_request           <= ~data_buffer_status_latch.empty && ~edge_data_write_buffer_status.alfull;
				vertex_num_counter_resp_out <= vertex_num_counter_resp;
				edge_data_counter_accum_out <= edge_data_counter_accum;
				break_S_out                 <= break_S1[0];
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_write_out.payload <= edge_data_write_buffer.payload;
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_job_latched.valid          <= 0;
			data_buffer_status_latch          <= 0;
			data_buffer_status_latch.empty    <= 1;
			write_response_in_latched.valid   <= 0;
			write_buffer_status_latched       <= 0;
			write_buffer_status_latched.empty <= 1;
		end else begin
			if(enabled) begin
				vertex_job_latched.valid        <= vertex_job.valid;
				data_buffer_status_latch        <= data_buffer_status;
				write_buffer_status_latched     <= write_buffer_status;
				write_response_in_latched.valid <= write_response_in.valid;
			end
		end
	end


	always_ff @(posedge clock) begin
		vertex_job_latched.payload        <= vertex_job.payload;
		write_response_in_latched.payload <= write_response_in.payload;
	end

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//edge_data_latched
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_latched.valid <= 0;
		end else begin
			if (enabled) begin
				edge_data_latched.valid <= edge_data.valid;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_latched.payload <= edge_data.payload;
	end


////////////////////////////////////////////////////////////////////////////
//edge_data_accumulate
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_update             <= 0;
			edge_data_update_latch.valid <= 0;
			break_S1                     <= 0;
			inverse_out_degree_counter   <= 0;
		end else begin
			if (enabled && vertex_job_latched.valid) begin
				if(edge_data_latched.valid && (|edge_data_latched.payload.data) && (edge_data_latched.payload.src == vertex_job_latched.payload.id) && ~(|break_S1) )begin
					edge_data_update.valid           <= 1;
					edge_data_update.payload.index   <= vertex_job_latched.payload.id;
					edge_data_update.payload.cu_id_x <= CU_ID_X;
					edge_data_update.payload.cu_id_y <= CU_ID_Y;
					edge_data_update.payload.data_1  <= 1;
					edge_data_update.payload.data_2  <= edge_data_latched.payload.dest;
					break_S1[0]                      <= 1;
					inverse_out_degree_counter       <= 0;
				end else if (edge_data_latched.valid && ~(|edge_data_latched.payload.data) && (edge_data_latched.payload.src == vertex_job_latched.payload.id) && ~(|break_S1) ) begin
					inverse_out_degree_counter <= inverse_out_degree_counter -1;
					edge_data_update.valid     <= 0;
				end else begin
					edge_data_update.valid <= 0;
				end
			end else begin
				edge_data_update.valid <= 0;
			end

			if(~(|inverse_out_degree_counter) && vertex_job_latched.valid && ~(|break_S1)) begin
				break_S1[0] <= 1;
			end

			if(~(|inverse_out_degree_counter) && vertex_job.valid && ~vertex_job_latched.valid && ~(|break_S1)) begin
				inverse_out_degree_counter <= vertex_job.payload.inverse_out_degree;
			end

			if(break_S1[0])
				break_S1[0] <= 0;

			break_S1[1]                  <= break_S1[0];
			break_S1[2]                  <= break_S1[1];
			break_S1[3]                  <= break_S1[2];
			break_S1[4]                  <= break_S1[3];

			edge_data_update_latch.valid <= edge_data_update.valid;
		end
	end

	always_ff @(posedge clock) begin
		edge_data_update_latch.payload <= edge_data_update.payload;
	end
////////////////////////////////////////////////////////////////////////////
//counter trackings
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_counter_accum <= 0;
		end else begin
			if(write_response_in_latched.valid) begin
				edge_data_counter_accum <= edge_data_counter_accum + 1;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_num_counter_resp <= 0;
		end else begin
			if(write_response_in_latched.valid || (break_S1[1] && ~edge_data_update_latch.valid)) begin
				vertex_num_counter_resp <= vertex_num_counter_resp + 1;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
// write Edge DATA CU Buffers
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_data_write_bus_grant_latched <= 0;
			edge_data_write_bus_request       <= 0;
		end else begin
			if(enabled) begin
				edge_data_write_bus_grant_latched <= edge_data_write_bus_grant  && ~write_buffer_status_latched.alfull;
				edge_data_write_bus_request       <= edge_data_write_bus_request_latched;
			end
		end
	end

	assign edge_data_write_bus_request_latched = ~edge_data_write_buffer_status.empty && ~write_buffer_status_latched.alfull;
	assign edge_data_write_bus_request_pop     = edge_data_write_bus_grant_latched && ~write_buffer_status_latched.alfull;

	fifo #(
		.WIDTH($bits(EdgeDataWrite) ),
		.DEPTH(WRITE_CMD_BUFFER_SIZE)
	) edge_data_write_buffer_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (edge_data_update_latch.valid        ),
		.data_in (edge_data_update_latch              ),
		.full    (edge_data_write_buffer_status.full  ),
		.alFull  (edge_data_write_buffer_status.alfull),
		
		.pop     (edge_data_write_bus_request_pop     ),
		.valid   (edge_data_write_buffer_status.valid ),
		.data_out(edge_data_write_buffer              ),
		.empty   (edge_data_write_buffer_status.empty )
	);

endmodule