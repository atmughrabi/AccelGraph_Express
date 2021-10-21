// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_cache_resue_module.sv
// Create : 2021-10-20 18:45:25
// Revise : 2021-10-21 14:48:04
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_cache_resue_module #(
	parameter NUM_READ_REQUESTS = 4                   ,
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

	CommandBufferLine read_command_out_latched_full   [0:1];
	CommandBufferLine read_command_out_latched_payload[0:1];
	logic             read_command_out_latched_valid  [0:1];

////////////////////////////////////////////////////////////////////////////
// Read Command Arbitration
////////////////////////////////////////////////////////////////////////////

	logic [NUM_READ_REQUESTS-1:0] requests;
	logic [NUM_READ_REQUESTS-1:0] submit  ;

	logic [NUM_READ_REQUESTS-1:0] ready                       ;
	logic [NUM_READ_REQUESTS-1:0] ready_round_robin           ;
	logic                         round_robin_priority_enabled;

	BufferStatus      command_buffer_status          [0:NUM_READ_REQUESTS-1];
	CommandBufferLine command_buffer_in              [0:NUM_READ_REQUESTS-1];
	CommandBufferLine command_arbiter_out_round_robin                       ;
	CommandBufferLine command_arbiter_out                                   ;


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
//data request read logic extract single edgedata from cacheline
////////////////////////////////////////////////////////////////////////////

	cu_edge_data_read_extract_control cu_edge_data_read_extract_control_instant (
		.clock         (clock                 ),
		.rstn          (rstn_internal         ),
		.enabled_in    (enabled               ),
		.read_data_0_in(read_data_0_in_latched),
		.read_data_1_in(read_data_1_in_latched),
		.edge_data     (edge_data_variable    )
	);

	assign read_command_out_latched  = read_command_in_latched;
	assign read_response_out_latched = read_response_in_latched;
	assign read_data_0_out_latched   = read_data_0_in_latched;
	assign read_data_1_out_latched   = read_data_1_in_latched;

////////////////////////////////////////////////////////////////////////////
//Cache blocks
////////////////////////////////////////////////////////////////////////////

	ram #(
		.WIDTH(WIDTH),
		.DEPTH(DEPTH)
	) ram1_cache_tag_array_instant (
		.clock   (clock    ),
		.we      (we       ),
		.wr_addr (wr_addr  ),
		.data_in (data_in  ),
		
		.rd_addr (rd_addr1 ),
		.data_out(data_out1)
	);


	ram #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(DEPTH)
	) ram_cache_vertex_data_hot_array_instant (
		.clock   (clock    ),
		.we      (we       ),
		.wr_addr (wr_addr  ),
		.data_in (data_in  ),
		
		.rd_addr (rd_addr1 ),
		.data_out(data_out1)
	);

endmodule