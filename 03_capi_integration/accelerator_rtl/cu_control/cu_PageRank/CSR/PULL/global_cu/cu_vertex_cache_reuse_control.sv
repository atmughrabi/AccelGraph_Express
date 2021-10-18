// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_cache_reuse_control.sv
// Create : 2019-09-26 15:18:39
// Revise : 2021-10-18 18:28:53
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_cache_reuse_control #(
	parameter NUM_READ_REQUESTS = 2                   ,
	parameter NUM_GRAPH_CU      = NUM_GRAPH_CU_GLOBAL ,
	parameter NUM_VERTEX_CU     = NUM_VERTEX_CU_GLOBAL
) (
	input  logic              clock             , // Clock
	input  logic              rstn_in           ,
	input  logic              enabled_in        ,
	input  WEDInterface       wed_request_in    ,
	input  ResponseBufferLine read_response_in  ,
	input  ReadWriteDataLine  read_data_0_in    ,
	input  ReadWriteDataLine  read_data_1_in    ,
	input  BufferStatus       read_buffer_status,
	input  cu_configure_type  cu_configure      ,
	input  CommandBufferLine  read_command_in   ,
	output CommandBufferLine  read_command_out  ,
	output ResponseBufferLine read_response_out ,
	output ReadWriteDataLine  read_data_0_out   ,
	output ReadWriteDataLine  read_data_1_out
);


	logic rstn_internal;
	logic enabled      ;

////////////////////////////////////////////////////////////////////////////
// Input
////////////////////////////////////////////////////////////////////////////

	WEDInterface       wed_request_in_latched    ;
	ResponseBufferLine read_response_in_latched  ;
	ReadWriteDataLine  read_data_0_in_latched    ;
	ReadWriteDataLine  read_data_1_in_latched    ;
	BufferStatus       read_buffer_status_latched;
	CommandBufferLine  read_command_in_latched   ;
	cu_configure_type  cu_configure_latched      ;

////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////

	CommandBufferLine  read_command_out_latched ;
	ReadWriteDataLine  read_data_0_out_latched  ;
	ReadWriteDataLine  read_data_1_out_latched  ;
	ResponseBufferLine read_response_out_latched;

////////////////////////////////////////////////////////////////////////////
// logic signals read data/command input arbitration
////////////////////////////////////////////////////////////////////////////

	logic cache_miss;

	ReadWriteDataLine read_data_0_in_edge_job      ;
	ReadWriteDataLine read_data_1_in_edge_job      ;
	ReadWriteDataLine read_data_0_in_edge_data     ;
	ReadWriteDataLine read_data_1_in_edge_data     ;
	EdgeDataRead      edge_data_variable           ;
	ReadWriteDataLine read_data_0_data_out    [0:1];
	ReadWriteDataLine read_data_1_data_out    [0:1];

	ReadWriteDataLine read_data_0_data_out_latched[0:1];
	ReadWriteDataLine read_data_1_data_out_latched[0:1];

	logic read_data_0_data_out_latched_valid[0:1];
	logic read_data_1_data_out_latched_valid[0:1];


	CommandBufferLine read_command_out_edge_data;
	CommandBufferLine read_command_out_job_data ;

	CommandBufferLine read_command_out_latched_full   [0:1];
	CommandBufferLine read_command_out_latched_payload[0:1];
	logic             read_command_out_latched_valid  [0:1];

////////////////////////////////////////////////////////////////////////////
// logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn_internal <= 0;
		end else begin
			rstn_internal <= rstn_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			enabled <= 0;
		end else begin
			enabled <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			wed_request_in_latched.valid     <= 0;
			read_response_in_latched.valid   <= 0;
			read_data_0_in_latched.valid     <= 0;
			read_data_1_in_latched.valid     <= 0;
			read_buffer_status_latched       <= 0;
			read_buffer_status_latched.empty <= 1;
			read_command_in_latched.valid    <= 0;
			cu_configure_latched             <= 0;
		end else begin
			wed_request_in_latched.valid   <= wed_request_in.valid;
			read_response_in_latched.valid <= read_response_in.valid;
			read_data_0_in_latched.valid   <= read_data_0_in.valid ;
			read_data_1_in_latched.valid   <= read_data_1_in.valid;
			read_buffer_status_latched     <= read_buffer_status;
			read_command_in_latched.valid  <= read_command_in.valid;
			cu_configure_latched           <= cu_configure;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			wed_request_in_latched.payload   <= 0;
			read_response_in_latched.payload <= 0;
			read_data_0_in_latched.payload   <= 0;
			read_data_1_in_latched.payload   <= 0;
			read_command_in_latched.payload  <= 0;
		end else begin
			wed_request_in_latched.payload   <= wed_request_in.payload;
			read_response_in_latched.payload <= read_response_in.payload;
			read_data_0_in_latched.payload   <= read_data_0_in.payload ;
			read_data_1_in_latched.payload   <= read_data_1_in.payload;
			read_command_in_latched.payload  <= read_command_in.payload;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out.valid  <= 0;
			read_data_0_out.valid   <= 0;
			read_data_1_out.valid   <= 0;
			read_response_out.valid <= 0;
		end else begin
			if(enabled)begin
				read_command_out.valid  <= read_command_out_latched.valid;
				read_data_0_out.valid   <= read_data_0_out_latched.valid;
				read_data_1_out.valid   <= read_data_1_out_latched.valid;
				read_response_out.valid <= read_response_out_latched.valid;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out.payload  <= 0;
			read_data_0_out.payload   <= 0;
			read_data_1_out.payload   <= 0;
			read_response_out.payload <= 0;
		end else begin
			read_command_out.payload  <= read_command_out_latched.payload;
			read_data_0_out.payload   <= read_data_0_out_latched.payload;
			read_data_1_out.payload   <= read_data_1_out_latched.payload;
			read_response_out.payload <= read_response_out_latched.payload;
		end
	end


////////////////////////////////////////////////////////////////////////////
//cache reuse logic
////////////////////////////////////////////////////////////////////////////


	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			cache_miss <= 1;
		end else begin
			cache_miss <= 1;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_0_out_latched.valid   <= 0;
			read_data_1_out_latched.valid   <= 0;
			read_response_out_latched.valid <= 0;
		end else begin
			if(enabled)begin
				read_data_0_out_latched.valid   <= read_data_0_in_latched.valid ;
				read_data_1_out_latched.valid   <= read_data_1_in_latched.valid ;
				read_response_out_latched.valid <= read_response_in_latched.valid;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_0_out_latched.payload   <= 0;
			read_data_1_out_latched.payload   <= 0;
			read_response_out_latched.payload <= 0;
		end else begin
			read_data_0_out_latched.payload   <= read_data_0_in_latched.payload ;
			read_data_1_out_latched.payload   <= read_data_1_in_latched.payload ;
			read_response_out_latched.payload <= read_response_in_latched.payload;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched.valid <= 0;
		end else begin
			if(read_command_in_latched.valid & cache_miss & enabled)begin
				read_command_out_latched.valid <= read_command_in_latched.valid;
			end else begin
				read_command_out_latched.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched.payload <= 0;
		end else begin
			read_command_out_latched.payload <= read_command_in_latched.payload;
		end
	end

////////////////////////////////////////////////////////////////////////////
// Forward/Data Arbitration Logic
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//read data request logic - input
////////////////////////////////////////////////////////////////////////////

	array_struct_type_filter_command_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_0_array_struct_type_filter_command_demux_bus_instant (
		.clock         (clock                                          ),
		.rstn          (rstn_internal                                  ),
		.sel_in        (read_data_0_in_latched.payload.cmd.array_struct),
		.data_in       (read_data_0_in_latched                         ),
		.data_in_valid (read_data_0_in_latched.valid                   ),
		.data_out      (read_data_0_data_out_latched                   ),
		.data_out_valid(read_data_0_data_out_latched_valid             )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_0_data_out[0].valid <= 0;
			read_data_0_data_out[1].valid <= 0;
			read_data_0_data_out[0].payload <= 0;
			read_data_0_data_out[1].payload <= 0;
		end else begin
			read_data_0_data_out[0].valid <= read_data_0_data_out_latched_valid[0];
			read_data_0_data_out[1].valid <= read_data_0_data_out_latched_valid[1];
			read_data_0_data_out[0].payload <= read_data_0_data_out_latched[0].payload;
			read_data_0_data_out[1].payload <= read_data_0_data_out_latched[1].payload;
		end
	end

	assign read_data_0_in_edge_job  = read_data_0_data_out[0];
	assign read_data_0_in_edge_data = read_data_0_data_out[1];

	array_struct_type_filter_command_demux_bus #(
		.DATA_WIDTH($bits(ReadWriteDataLine)),
		.BUS_WIDTH (2                       )
	) read_data_1_array_struct_type_filter_command_demux_bus_instant (
		.clock         (clock                                          ),
		.rstn          (rstn_internal                                  ),
		.sel_in        (read_data_1_in_latched.payload.cmd.array_struct),
		.data_in       (read_data_1_in_latched                         ),
		.data_in_valid (read_data_1_in_latched.valid                   ),
		.data_out      (read_data_1_data_out_latched                   ),
		.data_out_valid(read_data_1_data_out_latched_valid             )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_1_data_out[0].valid <=0;
			read_data_1_data_out[1].valid <= 0;
			read_data_1_data_out[0].payload <= 0;
			read_data_1_data_out[1].payload <= 0;
		end else begin
			read_data_1_data_out[0].valid <= read_data_1_data_out_latched_valid[0];
			read_data_1_data_out[1].valid <= read_data_1_data_out_latched_valid[1];
			read_data_1_data_out[0].payload <= read_data_1_data_out_latched[0].payload;
			read_data_1_data_out[1].payload <= read_data_1_data_out_latched[1].payload;
		end
	end

	assign read_data_1_in_edge_job  = read_data_1_data_out[0];
	assign read_data_1_in_edge_data = read_data_1_data_out[1];

	////////////////////////////////////////////////////////////////////////////
	//data request read logic extract single edgedata from cacheline
	////////////////////////////////////////////////////////////////////////////

	cu_edge_data_read_extract_control cu_edge_data_read_extract_control_instant (
		.clock         (clock                   ),
		.rstn          (rstn_internal           ),
		.enabled_in    (enabled                 ),
		.read_data_0_in(read_data_0_in_edge_data),
		.read_data_1_in(read_data_1_in_edge_data),
		.edge_data     (edge_data_variable      )
	);

	////////////////////////////////////////////////////////////////////////////
	//read command request logic - input
	////////////////////////////////////////////////////////////////////////////

	array_struct_type_filter_command_demux_bus #(
		.DATA_WIDTH($bits(CommandBufferLine)),
		.BUS_WIDTH (2                       )
	) array_struct_type_filter_command_demux_bus_instant (
		.clock         (clock                                           ),
		.rstn          (rstn_internal                                   ),
		.sel_in        (read_command_in_latched.payload.cmd.array_struct),
		.data_in       (read_command_in_latched                         ),
		.data_in_valid (read_command_in_latched.valid                   ),
		.data_out      (read_command_out_latched_payload                ),
		.data_out_valid(read_command_out_latched_valid                  )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched_full[0].valid <= 0;
			read_command_out_latched_full[1].valid <= 0;
			read_command_out_latched_full[0].payload <= 0;
			read_command_out_latched_full[1].payload <= 0;
		end else begin
			read_command_out_latched_full[0].valid <= read_data_0_data_out_latched_valid[0];
			read_command_out_latched_full[1].valid <= read_data_0_data_out_latched_valid[1];
			read_command_out_latched_full[0].payload <= read_command_out_latched_payload[0];
			read_command_out_latched_full[1].payload <= read_command_out_latched_payload[1];
		end
	end

	assign read_command_out_job_data  = read_command_out_latched_full[0];
	assign read_command_out_edge_data = read_command_out_latched_full[1];



endmodule