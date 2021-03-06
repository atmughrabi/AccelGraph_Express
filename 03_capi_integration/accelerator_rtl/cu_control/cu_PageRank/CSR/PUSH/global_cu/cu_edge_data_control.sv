// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_edge_data_control.sv
// Create : 2019-09-26 15:18:46
// Revise : 2019-11-08 10:49:54
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------


import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_edge_data_control #(parameter CU_ID = 1) (
	input  logic              clock                   , // Clock
	input  logic              rstn                    ,
	input  logic              enabled_in              ,
	input  logic [0:63]       cu_configure            ,
	input  WEDInterface       wed_request_in          ,
	input  ResponseBufferLine read_response_in        ,
	input  EdgeDataRead       edge_data_read_in       ,
	input  BufferStatus       read_buffer_status      ,
	input  logic              edge_data_request       ,
	input  EdgeInterface      edge_job                ,
	output logic              edge_request            ,
	input  logic              read_command_bus_grant  ,
	output logic              read_command_bus_request,
	output CommandBufferLine  read_command_out        ,
	output BufferStatus       data_buffer_status      ,
	output EdgeDataRead       edge_data
);


	//output latched
	EdgeInterface edge_job_latched        ;
	EdgeInterface edge_job_variable       ;
	EdgeDataRead  edge_data_latched       ;
	BufferStatus  data_buffer_status_latch;

	logic read_command_bus_grant_latched      ;
	logic read_command_bus_grant_latched_NLOCK;
	logic read_command_bus_request_latched    ;
	//input lateched
	ResponseBufferLine read_response_in_latched                      ;
	logic              edge_request_latched                          ;
	BufferStatus       edge_buffer_status_internal                   ;
	WEDInterface       wed_request_in_latched                        ;
	CommandBufferLine  read_command_out_latched                      ;
	CommandBufferLine  read_command_out_latched_NLOCK                ;
	CommandBufferLine  read_command_out_latched_issue                ;
	BufferStatus       read_buffer_status_internal                   ;
	BufferStatus       read_buffer_status_internal_NLOCK             ;
	logic              enabled                                       ;
	logic              enabled_cmd                                   ;
	logic              edge_data_request_latched                     ;
	logic              edge_variable_pop                             ;
	EdgeDataRead       edge_data_variable                            ;
	logic [0:63]       cu_configure_latched                          ;
	CommandBufferLine  read_command_edge_data_burst_out_latched      ;
	CommandBufferLine  read_command_edge_data_burst_out_latched_NLOCK;


////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			enabled     <= 0;
			enabled_cmd <= 0;
		end else begin
			enabled     <= enabled_in;
			enabled_cmd <= enabled && (|cu_configure_latched);
		end
	end


////////////////////////////////////////////////////////////////////////////
//drive outputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			edge_request             <= 0;
			edge_data                <= 0;
			read_command_out         <= 0;
			data_buffer_status       <= 0;
			data_buffer_status.empty <= 1;
		end else begin
			if(enabled) begin
				edge_request       <= edge_request_latched;
				edge_data          <= edge_data_latched;
				read_command_out   <= read_command_edge_data_burst_out_latched;
				data_buffer_status <= data_buffer_status_latch;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_response_in_latched  <= 0;
			edge_job_latched          <= 0;
			edge_data_request_latched <= 0;
			wed_request_in_latched    <= 0;
			edge_data_variable        <= 0;
			cu_configure_latched      <= 0;
		end else begin
			if(enabled) begin
				wed_request_in_latched    <= wed_request_in;
				read_response_in_latched  <= read_response_in;
				edge_job_latched          <= edge_job;
				edge_data_variable        <= edge_data_read_in;
				edge_data_request_latched <= edge_data_request;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//data request command logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out_latched <= 0;
		end else begin
			if(enabled_cmd) begin
				if(edge_job_variable.valid && wed_request_in_latched.valid)begin
					read_command_out_latched.valid <= 1'b1;

					read_command_out_latched.address              <= wed_request_in_latched.wed.auxiliary1 + ((edge_job_variable.dest<< $clog2(DATA_SIZE_WRITE)) & ADDRESS_DATA_WRITE_ALIGN_MASK);
					read_command_out_latched.size                 <= 12'h080;
					read_command_out_latched.cmd.real_size        <= 1'b1;
					read_command_out_latched.cmd.real_size_bytes  <= DATA_SIZE_WRITE;
					read_command_out_latched.cmd.array_struct     <= READ_GRAPH_DATA;
					read_command_out_latched.cmd.cacheline_offset <= (((edge_job_variable.dest<< $clog2(DATA_SIZE_WRITE)) & ADDRESS_DATA_WRITE_ALIGN_MASK) >> $clog2(DATA_SIZE_WRITE));
					read_command_out_latched.cmd.cu_id            <= CU_ID;
					read_command_out_latched.cmd.cmd_type         <= CMD_READ;
					read_command_out_latched.cmd.address_offset   <= edge_job_variable.dest;

					read_command_out_latched.cmd.abt <= map_CABT(cu_configure_latched[10:12]);
					read_command_out_latched.abt     <= map_CABT(cu_configure_latched[10:12]);

					read_command_out_latched.command <= READ_CL_LCK;

				end else begin
					read_command_out_latched <= 0;
				end
			end
		end
	end

///////////////////////////////////////////////////////////////////////////
//Response Managment
///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_out_latched_NLOCK <= 0;
		end else begin
			if(read_response_in_latched.valid && read_response_in_latched.response == NLOCK) begin
				read_command_out_latched_NLOCK.valid <= 1'b1;

				read_command_out_latched_NLOCK.cmd     <= read_response_in_latched.cmd;
				read_command_out_latched_NLOCK.size    <= 12'h080;
				read_command_out_latched_NLOCK.address <= wed_request_in_latched.wed.auxiliary1 + (read_response_in_latched.cmd.cacheline_offset << $clog2(DATA_SIZE_WRITE));
				read_command_out_latched_NLOCK.abt     <= read_response_in_latched.cmd.abt;
				read_command_out_latched_NLOCK.command <= READ_CL_LCK;
			end else begin
				read_command_out_latched_NLOCK <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin 
		if(~rstn) begin
			read_command_out_latched_issue <= 0;
		end else begin
			if(read_command_edge_data_burst_out_latched_NLOCK.valid && ~read_command_out_latched.valid)
				read_command_out_latched_issue <= read_command_edge_data_burst_out_latched_NLOCK;
			else
				read_command_out_latched_issue <= read_command_out_latched;
		end
	end


///////////////////////////////////////////////////////////////////////////
//Edge data buffer
///////////////////////////////////////////////////////////////////////////

	fifo #(
		.WIDTH($bits(EdgeDataRead)    ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_data_buffer_fifo_instant (
		.clock   (clock                          ),
		.rstn    (rstn                           ),
		
		.push    (edge_data_variable.valid       ),
		.data_in (edge_data_variable             ),
		.full    (data_buffer_status_latch.full  ),
		.alFull  (data_buffer_status_latch.alfull),
		
		.pop     (edge_data_request_latched      ),
		.valid   (data_buffer_status_latch.valid ),
		.data_out(edge_data_latched              ),
		.empty   (data_buffer_status_latch.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Edge job buffer
///////////////////////////////////////////////////////////////////////////

	assign edge_request_latched = ~edge_buffer_status_internal.alfull; // request edges for Data job control
	assign edge_variable_pop    = ~edge_buffer_status_internal.empty && ~read_buffer_status_internal.alfull && read_buffer_status_internal_NLOCK.empty;

	fifo #(
		.WIDTH($bits(EdgeInterface)   ),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE)
	) edge_job_buffer_fifo_instant (
		.clock   (clock                             ),
		.rstn    (rstn                              ),
		
		.push    (edge_job_latched.valid            ),
		.data_in (edge_job_latched                  ),
		.full    (edge_buffer_status_internal.full  ),
		.alFull  (edge_buffer_status_internal.alfull),
		
		.pop     (edge_variable_pop                 ),
		.valid   (edge_buffer_status_internal.valid ),
		.data_out(edge_job_variable                 ),
		.empty   (edge_buffer_status_internal.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Read Command Edge double buffer
///////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_bus_grant_latched <= 0;
			read_command_bus_request       <= 0;
		end else begin
			if(enabled_cmd) begin
				read_command_bus_grant_latched <= read_command_bus_grant;
				read_command_bus_request       <= read_command_bus_request_latched;
			end
		end
	end

	assign read_command_bus_request_latched = ~read_buffer_status.alfull && ~read_buffer_status_internal.empty;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE )
	) read_command_edge_data_burst_fifo_instant (
		.clock   (clock                                   ),
		.rstn    (rstn                                    ),
		
		.push    (read_command_out_latched_issue.valid    ),
		.data_in (read_command_out_latched_issue          ),
		.full    (read_buffer_status_internal.full        ),
		.alFull  (read_buffer_status_internal.alfull      ),
		
		.pop     (read_command_bus_grant_latched          ),
		.valid   (read_buffer_status_internal.valid       ),
		.data_out(read_command_edge_data_burst_out_latched),
		.empty   (read_buffer_status_internal.empty       )
	);

	assign read_command_bus_grant_latched_NLOCK = ~read_buffer_status_internal.alfull && ~read_buffer_status_internal_NLOCK.empty && ~read_command_out_latched.valid;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(CU_EDGE_JOB_BUFFER_SIZE )
	) read_command_NLOCK_edge_data_burst_fifo_instant (
		.clock   (clock                                         ),
		.rstn    (rstn                                          ),
		
		.push    (read_command_out_latched_NLOCK.valid          ),
		.data_in (read_command_out_latched_NLOCK                ),
		.full    (read_buffer_status_internal_NLOCK.full        ),
		.alFull  (read_buffer_status_internal_NLOCK.alfull      ),
		
		.pop     (read_command_bus_grant_latched_NLOCK          ),
		.valid   (read_buffer_status_internal_NLOCK.valid       ),
		.data_out(read_command_edge_data_burst_out_latched_NLOCK),
		.empty   (read_buffer_status_internal_NLOCK.empty       )
	);



endmodule