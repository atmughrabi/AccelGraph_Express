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
// Revise : 2021-10-19 20:30:34
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_cache_reuse_control #(
	parameter NUM_READ_REQUESTS = 3                   ,
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

	BufferStatus      command_buffer_status          [NUM_READ_REQUESTS-1:0];
	CommandBufferLine command_buffer_in              [NUM_READ_REQUESTS-1:0];
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
			read_command_out_latched_full[0].valid <= read_command_out_latched_valid[0];
			read_command_out_latched_full[1].valid <= read_command_out_latched_valid[1];
			read_command_out_latched_full[0].payload <= read_command_out_latched_payload[0];
			read_command_out_latched_full[1].payload <= read_command_out_latched_payload[1];
		end
	end

	////////////////////////////////////////////////////////////////////////////
	// Read Command Arbitration
	////////////////////////////////////////////////////////////////////////////

	BufferStatus      command_buffer_status_0;
	CommandBufferLine command_buffer_in_0;

	BufferStatus      command_buffer_status_1;
	CommandBufferLine command_buffer_in_1;

	assign command_buffer_in_0 = command_buffer_in[0];
	assign command_buffer_in_1 = command_buffer_in[1];

	assign command_buffer_status_0 = command_buffer_status[0];
	assign command_buffer_status_1 = command_buffer_status[1];


	assign requests[1] = ~command_buffer_status[0].empty && ~read_buffer_status.alfull;
	assign requests[2] = ~command_buffer_status[1].empty && ~read_buffer_status.alfull;
	assign requests[0] = 0;

	assign submit[1] = command_buffer_in[0].valid;
	assign submit[2] = command_buffer_in[1].valid;
	assign submit[0] = 0;

	assign command_buffer_in[2] = 0;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_job_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn_internal                         ),
		
		.push    (read_command_out_latched_full[1].valid),
		.data_in (read_command_out_latched_full[1]      ),
		.full    (command_buffer_status[1].full         ),
		.alFull  (command_buffer_status[1].alfull       ),
		
		.pop     (ready[1]                              ),
		.valid   (command_buffer_status[1].valid        ),
		.data_out(command_buffer_in[1]                  ),
		.empty   (command_buffer_status[1].empty        )
	);

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_edge_data_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn_internal                         ),
		
		.push    (read_command_out_latched_full[2].valid),
		.data_in (read_command_out_latched_full[2]      ),
		.full    (command_buffer_status[2].full         ),
		.alFull  (command_buffer_status[2].alfull       ),
		
		.pop     (ready[2]                              ),
		.valid   (command_buffer_status[2].valid        ),
		.data_out(command_buffer_in[2]                  ),
		.empty   (command_buffer_status[2].empty        )
	);

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS(NUM_READ_REQUESTS       ),
		.WIDTH       ($bits(CommandBufferLine))
	) round_robin_priority_arbiter_N_input_1_ouput_command_buffer_arbiter_instant (
		.clock      (clock                          ),
		.rstn       (rstn_internal                  ),
		.enabled    (round_robin_priority_enabled   ),
		.buffer_in  (command_buffer_in              ),
		.submit     (submit                         ),
		.requests   (requests                       ),
		.arbiter_out(command_arbiter_out_round_robin),
		.ready      (ready_round_robin              )
	);


	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			command_arbiter_out.valid    <= 0;
			ready                        <= 0;
			round_robin_priority_enabled <= 0;
		end else begin
			if(enabled)begin
				command_arbiter_out.valid    <= command_arbiter_out_round_robin.valid;
				ready                        <= ready_round_robin;
				round_robin_priority_enabled <= 1;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			command_arbiter_out.payload <= 0;
		end else begin
			command_arbiter_out.payload <= command_arbiter_out_round_robin.payload ;
		end
	end
	////////////////////////////////////////////////////////////////////////////
	// Caching logic
	////////////////////////////////////////////////////////////////////////////

endmodule