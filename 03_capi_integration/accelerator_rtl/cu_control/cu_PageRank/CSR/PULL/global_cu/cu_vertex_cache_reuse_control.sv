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
// Revise : 2021-10-26 00:04:46
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_cache_reuse_control #(
	parameter NUM_READ_REQUESTS = 2   ,
	parameter NUM_HEAT_REGIONS  = 4   ,
	parameter NUM_CACHE_ENTRIES = 8192
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
// Vertex Criterion logic |HOT(3)|WARM(2)|LUKEWARM(1)|COLD(0)
////////////////////////////////////////////////////////////////////////////

	ReadWriteDataLine  read_data_0_edge_data_region  [0:NUM_HEAT_REGIONS-1];
	ReadWriteDataLine  read_data_1_edge_data_region  [0:NUM_HEAT_REGIONS-1];
	ResponseBufferLine response_data_edge_data_region[0:NUM_HEAT_REGIONS-1];
	CommandBufferLine  read_command_out_full_region  [0:NUM_HEAT_REGIONS-1];

	ReadWriteDataLine  read_data_0_edge_data_region_latched  [0:NUM_HEAT_REGIONS-1];
	ReadWriteDataLine  read_data_1_edge_data_region_latched  [0:NUM_HEAT_REGIONS-1];
	ResponseBufferLine response_data_edge_data_region_latched[0:NUM_HEAT_REGIONS-1];
	CommandBufferLine  read_command_out_full_region_latched  [0:NUM_HEAT_REGIONS-1];

	logic read_data_0_edge_data_region_valid  [0:NUM_HEAT_REGIONS-1];
	logic read_data_1_edge_data_region_valid  [0:NUM_HEAT_REGIONS-1];
	logic response_data_edge_data_region_valid[0:NUM_HEAT_REGIONS-1];
	logic read_command_out_full_region_valid  [0:NUM_HEAT_REGIONS-1];

////////////////////////////////////////////////////////////////////////////
// logic signals read data/command input arbitration
////////////////////////////////////////////////////////////////////////////

	logic cache_miss;

	ReadWriteDataLine read_data_0_in_edge_job;
	ReadWriteDataLine read_data_1_in_edge_job;

	ReadWriteDataLine  read_data_0_in_edge_data                         ;
	ReadWriteDataLine  read_data_1_in_edge_data                         ;
	ReadWriteDataLine  read_data_0_out_edge_data  [0:NUM_HEAT_REGIONS-1];
	ReadWriteDataLine  read_data_1_out_edge_data  [0:NUM_HEAT_REGIONS-1];
	ResponseBufferLine read_response_out_edge_data[0:NUM_HEAT_REGIONS-1];

	ResponseBufferLine reponse_data_in_edge_job           ;
	ResponseBufferLine reponse_data_in_edge_data          ;
	ResponseBufferLine reponse_data_out              [0:1];
	ResponseBufferLine reponse_data_out_latched      [0:1];
	logic              reponse_data_out_latched_valid[0:1];

	ReadWriteDataLine read_data_0_data_out[0:1];
	ReadWriteDataLine read_data_1_data_out[0:1];

	ReadWriteDataLine read_data_0_data_out_latched[0:1];
	ReadWriteDataLine read_data_1_data_out_latched[0:1];

	logic read_data_0_data_out_latched_valid[0:1];
	logic read_data_1_data_out_latched_valid[0:1];

	CommandBufferLine read_command_out_cache_full     [0:NUM_HEAT_REGIONS-1];
	CommandBufferLine read_command_out_latched_full   [                 0:1];
	CommandBufferLine read_command_out_latched_payload[                 0:1];
	logic             read_command_out_latched_valid  [                 0:1];

////////////////////////////////////////////////////////////////////////////
// Read Command Arbitration
////////////////////////////////////////////////////////////////////////////

	logic [(NUM_HEAT_REGIONS+1)-1:0] requests;
	logic [(NUM_HEAT_REGIONS+1)-1:0] submit  ;

	logic [(NUM_HEAT_REGIONS+1)-1:0] ready                       ;
	logic [(NUM_HEAT_REGIONS+1)-1:0] ready_round_robin           ;
	logic                            round_robin_priority_enabled;

	BufferStatus      command_buffer_status          [0:(NUM_HEAT_REGIONS+1)-1];
	CommandBufferLine command_buffer_in              [0:(NUM_HEAT_REGIONS+1)-1];
	CommandBufferLine command_arbiter_out_round_robin                          ;
	CommandBufferLine command_arbiter_out                                      ;

////////////////////////////////////////////////////////////////////////////
// Data Buffer Arbitration
////////////////////////////////////////////////////////////////////////////

	logic [(NUM_HEAT_REGIONS+1)-1:0] data_0_requests;
	logic [(NUM_HEAT_REGIONS+1)-1:0] data_0_submit  ;

	logic [(NUM_HEAT_REGIONS+1)-1:0] data_0_ready                       ;
	logic [(NUM_HEAT_REGIONS+1)-1:0] data_0_ready_round_robin           ;
	logic                        data_0_round_robin_priority_enabled;

	BufferStatus      data_0_buffer_status          [0:(NUM_HEAT_REGIONS+1)-1];
	ReadWriteDataLine data_0_buffer_in              [0:(NUM_HEAT_REGIONS+1)-1];
	ReadWriteDataLine data_0_arbiter_out_round_robin                          ;
	ReadWriteDataLine data_0_arbiter_out                                      ;

	logic [(NUM_HEAT_REGIONS+1)-1:0] data_1_requests;
	logic [(NUM_HEAT_REGIONS+1)-1:0] data_1_submit  ;

	logic [(NUM_HEAT_REGIONS+1)-1:0] data_1_ready                       ;
	logic [(NUM_HEAT_REGIONS+1)-1:0] data_1_ready_round_robin           ;
	logic                        data_1_round_robin_priority_enabled;

	BufferStatus      data_1_buffer_status          [0:(NUM_HEAT_REGIONS+1)-1];
	ReadWriteDataLine data_1_buffer_in              [0:(NUM_HEAT_REGIONS+1)-1];
	ReadWriteDataLine data_1_arbiter_out_round_robin                          ;
	ReadWriteDataLine data_1_arbiter_out                                      ;

	logic [(NUM_HEAT_REGIONS+1)-1:0] read_response_requests;
	logic [(NUM_HEAT_REGIONS+1)-1:0] read_response_submit  ;

	logic [(NUM_HEAT_REGIONS+1)-1:0] read_response_ready                       ;
	logic [(NUM_HEAT_REGIONS+1)-1:0] read_response_ready_round_robin           ;
	logic                            read_response_round_robin_priority_enabled;

	BufferStatus       read_response_buffer_status          [0:(NUM_HEAT_REGIONS+1)-1];
	ResponseBufferLine read_response_buffer_in              [0:(NUM_HEAT_REGIONS+1)-1];
	ResponseBufferLine read_response_arbiter_out_round_robin                          ;
	ResponseBufferLine read_response_arbiter_out                                      ;

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
				read_data_0_out_latched.valid   <= data_0_arbiter_out.valid ;
				read_data_1_out_latched.valid   <= data_1_arbiter_out.valid ;
				read_response_out_latched.valid <= read_response_arbiter_out.valid;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_0_out_latched.payload   <= 0;
			read_data_1_out_latched.payload   <= 0;
			read_response_out_latched.payload <= 0;
		end else begin
			read_data_0_out_latched.payload   <= data_0_arbiter_out.payload ;
			read_data_1_out_latched.payload   <= data_1_arbiter_out.payload ;
			read_response_out_latched.payload <= read_response_arbiter_out.payload;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched.valid <= 0;
		end else begin
			if(command_arbiter_out.valid & cache_miss & enabled)begin
				read_command_out_latched.valid <= command_arbiter_out.valid;
			end else begin
				read_command_out_latched.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched.payload <= 0;
		end else begin
			read_command_out_latched.payload <= command_arbiter_out.payload;
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

	assign read_data_0_in_edge_job  = read_data_0_in_latched;
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

	assign read_data_1_in_edge_job  = read_data_1_in_latched;
	assign read_data_1_in_edge_data = read_data_1_data_out[1];

	array_struct_type_filter_command_demux_bus #(
		.DATA_WIDTH($bits(ResponseBufferLine)),
		.BUS_WIDTH (2                        )
	) response_struct_type_filter_demux_bus_instant (
		.clock         (clock                                            ),
		.rstn          (rstn_internal                                    ),
		.sel_in        (read_response_in_latched.payload.cmd.array_struct),
		.data_in       (read_response_in_latched                         ),
		.data_in_valid (read_response_in_latched.valid                   ),
		.data_out      (reponse_data_out_latched                         ),
		.data_out_valid(reponse_data_out_latched_valid                   )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			reponse_data_out[0].valid <=0;
			reponse_data_out[1].valid <= 0;
			reponse_data_out[0].payload <= 0;
			reponse_data_out[1].payload <= 0;
		end else begin
			reponse_data_out[0].valid <= reponse_data_out_latched_valid[0];
			reponse_data_out[1].valid <= reponse_data_out_latched_valid[1];
			reponse_data_out[0].payload <= reponse_data_out_latched[0].payload;
			reponse_data_out[1].payload <= reponse_data_out_latched[1].payload;
		end
	end

	assign reponse_data_in_edge_job  = read_response_in_latched;
	assign reponse_data_in_edge_data = reponse_data_out[1];

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

	assign requests[0] = ~command_buffer_status[0].empty && ~read_buffer_status_latched.alfull;
	assign requests[1] = ~command_buffer_status[1].empty && ~read_buffer_status_latched.alfull;
	assign requests[2] = ~command_buffer_status[2].empty && ~read_buffer_status_latched.alfull;
	assign requests[3] = ~command_buffer_status[3].empty && ~read_buffer_status_latched.alfull;
	assign requests[4] = ~command_buffer_status[4].empty && ~read_buffer_status_latched.alfull;


	assign submit[0] = command_buffer_in[0].valid;
	assign submit[1] = command_buffer_in[1].valid;
	assign submit[2] = command_buffer_in[2].valid;
	assign submit[3] = command_buffer_in[3].valid;
	assign submit[4] = command_buffer_in[4].valid;


	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_job_fifo_instant (
		.clock   (clock                                 ),
		.rstn    (rstn_internal                         ),
		
		.push    (read_command_out_latched_full[0].valid),
		.data_in (read_command_out_latched_full[0]      ),
		.full    (command_buffer_status[0].full         ),
		.alFull  (command_buffer_status[0].alfull       ),
		
		.pop     (ready[0]                              ),
		.valid   (command_buffer_status[0].valid        ),
		.data_out(command_buffer_in[0]                  ),
		.empty   (command_buffer_status[0].empty        )
	);

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_edge_data_fifo_0_instant (
		.clock   (clock                               ),
		.rstn    (rstn_internal                       ),
		
		.push    (read_command_out_cache_full[0].valid),
		.data_in (read_command_out_cache_full[0]      ),
		.full    (command_buffer_status[1].full       ),
		.alFull  (command_buffer_status[1].alfull     ),
		
		.pop     (ready[1]                            ),
		.valid   (command_buffer_status[1].valid      ),
		.data_out(command_buffer_in[1]                ),
		.empty   (command_buffer_status[1].empty      )
	);

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_edge_data_fifo_1_instant (
		.clock   (clock                               ),
		.rstn    (rstn_internal                       ),
		
		.push    (read_command_out_cache_full[1].valid),
		.data_in (read_command_out_cache_full[1]      ),
		.full    (command_buffer_status[2].full       ),
		.alFull  (command_buffer_status[2].alfull     ),
		
		.pop     (ready[2]                            ),
		.valid   (command_buffer_status[2].valid      ),
		.data_out(command_buffer_in[2]                ),
		.empty   (command_buffer_status[2].empty      )
	);

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_edge_data_fifo_2_instant (
		.clock   (clock                               ),
		.rstn    (rstn_internal                       ),
		
		.push    (read_command_out_cache_full[2].valid),
		.data_in (read_command_out_cache_full[2]      ),
		.full    (command_buffer_status[3].full       ),
		.alFull  (command_buffer_status[3].alfull     ),
		
		.pop     (ready[3]                            ),
		.valid   (command_buffer_status[3].valid      ),
		.data_out(command_buffer_in[3]                ),
		.empty   (command_buffer_status[3].empty      )
	);

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_command_out_edge_data_fifo_3_instant (
		.clock   (clock                               ),
		.rstn    (rstn_internal                       ),
		
		.push    (read_command_out_cache_full[3].valid),
		.data_in (read_command_out_cache_full[3]      ),
		.full    (command_buffer_status[4].full       ),
		.alFull  (command_buffer_status[4].alfull     ),
		
		.pop     (ready[4]                            ),
		.valid   (command_buffer_status[4].valid      ),
		.data_out(command_buffer_in[4]                ),
		.empty   (command_buffer_status[4].empty      )
	);

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS((NUM_HEAT_REGIONS+1)    ),
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
// Read Command Arbitration logic
////////////////////////////////////////////////////////////////////////////

	assign data_0_requests[0] = ~data_0_buffer_status[0].empty && ~read_buffer_status_latched.alfull;
	assign data_0_requests[1] = ~data_0_buffer_status[1].empty && ~read_buffer_status_latched.alfull;
	assign data_0_requests[2] = ~data_0_buffer_status[2].empty && ~read_buffer_status_latched.alfull;
	assign data_0_requests[3] = ~data_0_buffer_status[3].empty && ~read_buffer_status_latched.alfull;
	assign data_0_requests[4] = ~data_0_buffer_status[4].empty && ~read_buffer_status_latched.alfull;


	assign data_0_submit[0] = data_0_buffer_in[0].valid;
	assign data_0_submit[1] = data_0_buffer_in[1].valid;
	assign data_0_submit[2] = data_0_buffer_in[2].valid;
	assign data_0_submit[3] = data_0_buffer_in[3].valid;
	assign data_0_submit[4] = data_0_buffer_in[4].valid;


	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_0_out_job_fifo_instant (
		.clock   (clock                         ),
		.rstn    (rstn_internal                 ),
		
		.push    (read_data_0_in_edge_job.valid ),
		.data_in (read_data_0_in_edge_job       ),
		.full    (data_0_buffer_status[0].full  ),
		.alFull  (data_0_buffer_status[0].alfull),
		
		.pop     (data_0_ready[0]               ),
		.valid   (data_0_buffer_status[0].valid ),
		.data_out(data_0_buffer_in[0]           ),
		.empty   (data_0_buffer_status[0].empty )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_0_out_edge_data_fifo_0_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_0_out_edge_data[0].valid),
		.data_in (read_data_0_out_edge_data[0]      ),
		.full    (data_0_buffer_status[1].full      ),
		.alFull  (data_0_buffer_status[1].alfull    ),
		
		.pop     (data_0_ready[1]                   ),
		.valid   (data_0_buffer_status[1].valid     ),
		.data_out(data_0_buffer_in[1]               ),
		.empty   (data_0_buffer_status[1].empty     )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_0_out_edge_data_fifo_1_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_0_out_edge_data[1].valid),
		.data_in (read_data_0_out_edge_data[1]      ),
		.full    (data_0_buffer_status[2].full      ),
		.alFull  (data_0_buffer_status[2].alfull    ),
		
		.pop     (data_0_ready[2]                   ),
		.valid   (data_0_buffer_status[2].valid     ),
		.data_out(data_0_buffer_in[2]               ),
		.empty   (data_0_buffer_status[2].empty     )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_0_out_edge_data_fifo_2_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_0_out_edge_data[2].valid),
		.data_in (read_data_0_out_edge_data[2]      ),
		.full    (data_0_buffer_status[3].full      ),
		.alFull  (data_0_buffer_status[3].alfull    ),
		
		.pop     (data_0_ready[3]                   ),
		.valid   (data_0_buffer_status[3].valid     ),
		.data_out(data_0_buffer_in[3]               ),
		.empty   (data_0_buffer_status[3].empty     )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_0_out_edge_data_fifo_3_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_0_out_edge_data[3].valid),
		.data_in (read_data_0_out_edge_data[3]      ),
		.full    (data_0_buffer_status[4].full      ),
		.alFull  (data_0_buffer_status[4].alfull    ),
		
		.pop     (data_0_ready[4]                   ),
		.valid   (data_0_buffer_status[4].valid     ),
		.data_out(data_0_buffer_in[4]               ),
		.empty   (data_0_buffer_status[4].empty     )
	);

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS((NUM_HEAT_REGIONS+1)    ),
		.WIDTH       ($bits(ReadWriteDataLine))
	) round_robin_priority_arbiter_N_input_1_ouput_data_0_buffer_arbiter_instant (
		.clock      (clock                              ),
		.rstn       (rstn_internal                      ),
		.enabled    (data_0_round_robin_priority_enabled),
		.buffer_in  (data_0_buffer_in                   ),
		.submit     (data_0_submit                      ),
		.requests   (data_0_requests                    ),
		.arbiter_out(data_0_arbiter_out_round_robin     ),
		.ready      (data_0_ready_round_robin           )
	);


	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			data_0_arbiter_out.valid            <= 0;
			data_0_ready                        <= 0;
			data_0_round_robin_priority_enabled <= 0;
		end else begin
			if(enabled)begin
				data_0_arbiter_out.valid            <= data_0_arbiter_out_round_robin.valid;
				data_0_ready                        <= data_0_ready_round_robin;
				data_0_round_robin_priority_enabled <= 1;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			data_0_arbiter_out.payload <= 0;
		end else begin
			data_0_arbiter_out.payload <= data_0_arbiter_out_round_robin.payload ;
		end
	end


////////////////////////////////////////////////////////////////////////////
// Read Command Arbitration
////////////////////////////////////////////////////////////////////////////
	assign data_1_requests[0] = ~data_1_buffer_status[0].empty && ~read_buffer_status_latched.alfull;
	assign data_1_requests[1] = ~data_1_buffer_status[1].empty && ~read_buffer_status_latched.alfull;
	assign data_1_requests[2] = ~data_1_buffer_status[2].empty && ~read_buffer_status_latched.alfull;
	assign data_1_requests[3] = ~data_1_buffer_status[3].empty && ~read_buffer_status_latched.alfull;
	assign data_1_requests[4] = ~data_1_buffer_status[4].empty && ~read_buffer_status_latched.alfull;


	assign data_1_submit[0] = data_1_buffer_in[0].valid;
	assign data_1_submit[1] = data_1_buffer_in[1].valid;
	assign data_1_submit[2] = data_1_buffer_in[2].valid;
	assign data_1_submit[3] = data_1_buffer_in[3].valid;
	assign data_1_submit[4] = data_1_buffer_in[4].valid;


	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_1_out_job_fifo_instant (
		.clock   (clock                         ),
		.rstn    (rstn_internal                 ),
		
		.push    (read_data_1_in_edge_job.valid ),
		.data_in (read_data_1_in_edge_job       ),
		.full    (data_1_buffer_status[0].full  ),
		.alFull  (data_1_buffer_status[0].alfull),
		
		.pop     (data_1_ready[0]               ),
		.valid   (data_1_buffer_status[0].valid ),
		.data_out(data_1_buffer_in[0]           ),
		.empty   (data_1_buffer_status[0].empty )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_1_out_edge_data_fifo_0_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_1_out_edge_data[0].valid),
		.data_in (read_data_1_out_edge_data[0]      ),
		.full    (data_1_buffer_status[1].full      ),
		.alFull  (data_1_buffer_status[1].alfull    ),
		
		.pop     (data_1_ready[1]                   ),
		.valid   (data_1_buffer_status[1].valid     ),
		.data_out(data_1_buffer_in[1]               ),
		.empty   (data_1_buffer_status[1].empty     )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_1_out_edge_data_fifo_1_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_1_out_edge_data[1].valid),
		.data_in (read_data_1_out_edge_data[1]      ),
		.full    (data_1_buffer_status[2].full      ),
		.alFull  (data_1_buffer_status[2].alfull    ),
		
		.pop     (data_1_ready[2]                   ),
		.valid   (data_1_buffer_status[2].valid     ),
		.data_out(data_1_buffer_in[2]               ),
		.empty   (data_1_buffer_status[2].empty     )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_1_out_edge_data_fifo_2_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_1_out_edge_data[2].valid),
		.data_in (read_data_1_out_edge_data[2]      ),
		.full    (data_1_buffer_status[3].full      ),
		.alFull  (data_1_buffer_status[3].alfull    ),
		
		.pop     (data_1_ready[3]                   ),
		.valid   (data_1_buffer_status[3].valid     ),
		.data_out(data_1_buffer_in[3]               ),
		.empty   (data_1_buffer_status[3].empty     )
	);

	fifo #(
		.WIDTH($bits(ReadWriteDataLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE    )
	) read_data_1_out_edge_data_fifo_3_instant (
		.clock   (clock                             ),
		.rstn    (rstn_internal                     ),
		
		.push    (read_data_1_out_edge_data[3].valid),
		.data_in (read_data_1_out_edge_data[3]      ),
		.full    (data_1_buffer_status[4].full      ),
		.alFull  (data_1_buffer_status[4].alfull    ),
		
		.pop     (data_1_ready[4]                   ),
		.valid   (data_1_buffer_status[4].valid     ),
		.data_out(data_1_buffer_in[4]               ),
		.empty   (data_1_buffer_status[4].empty     )
	);

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS((NUM_HEAT_REGIONS+1)    ),
		.WIDTH       ($bits(ReadWriteDataLine))
	) round_robin_priority_arbiter_N_input_1_ouput_data_1_buffer_arbiter_instant (
		.clock      (clock                              ),
		.rstn       (rstn_internal                      ),
		.enabled    (data_1_round_robin_priority_enabled),
		.buffer_in  (data_1_buffer_in                   ),
		.submit     (data_1_submit                      ),
		.requests   (data_1_requests                    ),
		.arbiter_out(data_1_arbiter_out_round_robin     ),
		.ready      (data_1_ready_round_robin           )
	);


	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			data_1_arbiter_out.valid            <= 0;
			data_1_ready                        <= 0;
			data_1_round_robin_priority_enabled <= 0;
		end else begin
			if(enabled)begin
				data_1_arbiter_out.valid            <= data_1_arbiter_out_round_robin.valid;
				data_1_ready                        <= data_1_ready_round_robin;
				data_1_round_robin_priority_enabled <= 1;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			data_1_arbiter_out.payload <= 0;
		end else begin
			data_1_arbiter_out.payload <= data_1_arbiter_out_round_robin.payload ;
		end
	end


////////////////////////////////////////////////////////////////////////////
// Response Arbitration
////////////////////////////////////////////////////////////////////////////

	assign read_response_requests[0] = ~read_response_buffer_status[0].empty && ~read_buffer_status_latched.alfull;
	assign read_response_requests[1] = ~read_response_buffer_status[1].empty && ~read_buffer_status_latched.alfull;
	assign read_response_requests[2] = ~read_response_buffer_status[2].empty && ~read_buffer_status_latched.alfull;
	assign read_response_requests[3] = ~read_response_buffer_status[3].empty && ~read_buffer_status_latched.alfull;
	assign read_response_requests[4] = ~read_response_buffer_status[4].empty && ~read_buffer_status_latched.alfull;


	assign read_response_submit[0] = read_response_buffer_in[0].valid;
	assign read_response_submit[1] = read_response_buffer_in[1].valid;
	assign read_response_submit[2] = read_response_buffer_in[2].valid;
	assign read_response_submit[3] = read_response_buffer_in[3].valid;
	assign read_response_submit[4] = read_response_buffer_in[4].valid;


	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE     )
	) response_out_job_fifo_instant (
		.clock   (clock                                ),
		.rstn    (rstn_internal                        ),
		
		.push    (reponse_data_in_edge_job.valid       ),
		.data_in (reponse_data_in_edge_job             ),
		.full    (read_response_buffer_status[0].full  ),
		.alFull  (read_response_buffer_status[0].alfull),
		
		.pop     (read_response_ready[0]               ),
		.valid   (read_response_buffer_status[0].valid ),
		.data_out(read_response_buffer_in[0]           ),
		.empty   (read_response_buffer_status[0].empty )
	);

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE     )
	) response_out_edge_data_fifo_0_instant (
		.clock   (clock                                ),
		.rstn    (rstn_internal                        ),
		
		.push    (read_response_out_edge_data[0].valid      ),
		.data_in (read_response_out_edge_data[0]            ),
		.full    (read_response_buffer_status[1].full  ),
		.alFull  (read_response_buffer_status[1].alfull),
		
		.pop     (read_response_ready[1]               ),
		.valid   (read_response_buffer_status[1].valid ),
		.data_out(read_response_buffer_in[1]           ),
		.empty   (read_response_buffer_status[1].empty )
	);

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE     )
	) response_out_edge_data_fifo_1_instant (
		.clock   (clock                                ),
		.rstn    (rstn_internal                        ),
		
		.push    (read_response_out_edge_data[1].valid      ),
		.data_in (read_response_out_edge_data[1]            ),
		.full    (read_response_buffer_status[2].full  ),
		.alFull  (read_response_buffer_status[2].alfull),
		
		.pop     (read_response_ready[2]               ),
		.valid   (read_response_buffer_status[2].valid ),
		.data_out(read_response_buffer_in[2]           ),
		.empty   (read_response_buffer_status[2].empty )
	);

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE     )
	) response_out_edge_data_fifo_2_instant (
		.clock   (clock                                ),
		.rstn    (rstn_internal                        ),
		
		.push    (read_response_out_edge_data[2].valid      ),
		.data_in (read_response_out_edge_data[2]            ),
		.full    (read_response_buffer_status[3].full  ),
		.alFull  (read_response_buffer_status[3].alfull),
		
		.pop     (read_response_ready[3]               ),
		.valid   (read_response_buffer_status[3].valid ),
		.data_out(read_response_buffer_in[3]           ),
		.empty   (read_response_buffer_status[3].empty )
	);

	fifo #(
		.WIDTH($bits(ResponseBufferLine)),
		.DEPTH(READ_CMD_BUFFER_SIZE     )
	) response_out_edge_data_fifo_3_instant (
		.clock   (clock                                ),
		.rstn    (rstn_internal                        ),
		
		.push    (read_response_out_edge_data[3].valid      ),
		.data_in (read_response_out_edge_data[3]            ),
		.full    (read_response_buffer_status[4].full  ),
		.alFull  (read_response_buffer_status[4].alfull),
		
		.pop     (read_response_ready[4]               ),
		.valid   (read_response_buffer_status[4].valid ),
		.data_out(read_response_buffer_in[4]           ),
		.empty   (read_response_buffer_status[4].empty )
	);

	round_robin_priority_arbiter_N_input_1_ouput #(
		.NUM_REQUESTS((NUM_HEAT_REGIONS+1)     ),
		.WIDTH       ($bits(ResponseBufferLine))
	) round_robin_priority_arbiter_N_input_1_ouput_read_response_buffer_arbiter_instant (
		.clock      (clock                                     ),
		.rstn       (rstn_internal                             ),
		.enabled    (read_response_round_robin_priority_enabled),
		.buffer_in  (read_response_buffer_in                   ),
		.submit     (read_response_submit                      ),
		.requests   (read_response_requests                    ),
		.arbiter_out(read_response_arbiter_out_round_robin     ),
		.ready      (read_response_ready_round_robin           )
	);


	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_response_arbiter_out.valid            <= 0;
			read_response_ready                        <= 0;
			read_response_round_robin_priority_enabled <= 0;
		end else begin
			if(enabled)begin
				read_response_arbiter_out.valid            <= read_response_arbiter_out_round_robin.valid;
				read_response_ready                        <= read_response_ready_round_robin;
				read_response_round_robin_priority_enabled <= 1;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_response_arbiter_out.payload <= 0;
		end else begin
			read_response_arbiter_out.payload <= read_response_arbiter_out_round_robin.payload ;
		end
	end

////////////////////////////////////////////////////////////////////////////
// Vertex Criterion logic |HOT(3)|WARM(2)|LUKEWARM(1)|COLD(0)
////////////////////////////////////////////////////////////////////////////

	array_struct_type_filter_vertex_criterion_demux_bus #(.DATA_WIDTH($bits(ReadWriteDataLine))) array_struct_type_filter_vertex_criterion_data_0_demux_bus_instant (
		.clock         (clock                                        ),
		.rstn          (rstn_internal                                ),
		.sel_in        (read_data_0_in_edge_data.payload.cmd.aux_data[32:63]),
		.data_in       (read_data_0_in_edge_data                     ),
		.data_in_valid (read_data_0_in_edge_data.valid               ),
		.data_out      (read_data_0_edge_data_region_latched         ),
		.data_out_valid(read_data_0_edge_data_region_valid           )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_0_edge_data_region[0].valid <= 0;
			read_data_0_edge_data_region[1].valid <= 0;
			read_data_0_edge_data_region[2].valid <= 0;
			read_data_0_edge_data_region[3].valid <= 0;

			read_data_0_edge_data_region[0].payload <= 0;
			read_data_0_edge_data_region[1].payload <= 0;
			read_data_0_edge_data_region[2].payload <= 0;
			read_data_0_edge_data_region[3].payload <= 0;
		end else begin
			read_data_0_edge_data_region[0].valid <= read_data_0_edge_data_region_valid[0];
			read_data_0_edge_data_region[1].valid <= read_data_0_edge_data_region_valid[1];
			read_data_0_edge_data_region[2].valid <= read_data_0_edge_data_region_valid[2];
			read_data_0_edge_data_region[3].valid <= read_data_0_edge_data_region_valid[3];

			read_data_0_edge_data_region[0].payload <= read_data_0_edge_data_region_latched[0].payload;
			read_data_0_edge_data_region[1].payload <= read_data_0_edge_data_region_latched[1].payload;
			read_data_0_edge_data_region[2].payload <= read_data_0_edge_data_region_latched[2].payload;
			read_data_0_edge_data_region[3].payload <= read_data_0_edge_data_region_latched[3].payload;
		end
	end

	array_struct_type_filter_vertex_criterion_demux_bus #(.DATA_WIDTH($bits(ReadWriteDataLine))) array_struct_type_filter_vertex_criterion_data_1_demux_bus_instant (
		.clock         (clock                                        ),
		.rstn          (rstn_internal                                ),
		.sel_in        (read_data_1_in_edge_data.payload.cmd.aux_data[32:63]),
		.data_in       (read_data_1_in_edge_data                     ),
		.data_in_valid (read_data_1_in_edge_data.valid               ),
		.data_out      (read_data_1_edge_data_region_latched         ),
		.data_out_valid(read_data_1_edge_data_region_valid           )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_data_1_edge_data_region[0].valid <= 0;
			read_data_1_edge_data_region[1].valid <= 0;
			read_data_1_edge_data_region[2].valid <= 0;
			read_data_1_edge_data_region[3].valid <= 0;

			read_data_1_edge_data_region[0].payload <= 0;
			read_data_1_edge_data_region[1].payload <= 0;
			read_data_1_edge_data_region[2].payload <= 0;
			read_data_1_edge_data_region[3].payload <= 0;
		end else begin
			read_data_1_edge_data_region[0].valid <= read_data_1_edge_data_region_valid[0];
			read_data_1_edge_data_region[1].valid <= read_data_1_edge_data_region_valid[1];
			read_data_1_edge_data_region[2].valid <= read_data_1_edge_data_region_valid[2];
			read_data_1_edge_data_region[3].valid <= read_data_1_edge_data_region_valid[3];

			read_data_1_edge_data_region[0].payload <= read_data_1_edge_data_region_latched[0].payload;
			read_data_1_edge_data_region[1].payload <= read_data_1_edge_data_region_latched[1].payload;
			read_data_1_edge_data_region[2].payload <= read_data_1_edge_data_region_latched[2].payload;
			read_data_1_edge_data_region[3].payload <= read_data_1_edge_data_region_latched[3].payload;
		end
	end

	array_struct_type_filter_vertex_criterion_demux_bus #(.DATA_WIDTH($bits(ResponseBufferLine))) array_struct_type_filter_vertex_criterion_response_demux_bus_instant (
		.clock         (clock                                         ),
		.rstn          (rstn_internal                                 ),
		.sel_in        (reponse_data_in_edge_data.payload.cmd.aux_data[32:63]),
		.data_in       (reponse_data_in_edge_data                     ),
		.data_in_valid (reponse_data_in_edge_data.valid               ),
		.data_out      (response_data_edge_data_region_latched        ),
		.data_out_valid(response_data_edge_data_region_valid          )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			response_data_edge_data_region[0].valid <= 0;
			response_data_edge_data_region[1].valid <= 0;
			response_data_edge_data_region[2].valid <= 0;
			response_data_edge_data_region[3].valid <= 0;

			response_data_edge_data_region[0].payload <= 0;
			response_data_edge_data_region[1].payload <= 0;
			response_data_edge_data_region[2].payload <= 0;
			response_data_edge_data_region[3].payload <= 0;
		end else begin
			response_data_edge_data_region[0].valid <= response_data_edge_data_region_valid[0];
			response_data_edge_data_region[1].valid <= response_data_edge_data_region_valid[1];
			response_data_edge_data_region[2].valid <= response_data_edge_data_region_valid[2];
			response_data_edge_data_region[3].valid <= response_data_edge_data_region_valid[3];

			response_data_edge_data_region[0].payload <= response_data_edge_data_region_latched[0].payload;
			response_data_edge_data_region[1].payload <= response_data_edge_data_region_latched[1].payload;
			response_data_edge_data_region[2].payload <= response_data_edge_data_region_latched[2].payload;
			response_data_edge_data_region[3].payload <= response_data_edge_data_region_latched[3].payload;
		end
	end

	array_struct_type_filter_vertex_criterion_demux_bus #(.DATA_WIDTH($bits(CommandBufferLine))) array_struct_type_filter_vertex_criterion_command_demux_bus_instant (
		.clock         (clock                                                ),
		.rstn          (rstn_internal                                        ),
		.sel_in        (read_command_out_latched_full[1].payload.cmd.aux_data[32:63]),
		.data_in       (read_command_out_latched_full[1]                     ),
		.data_in_valid (read_command_out_latched_full[1].valid               ),
		.data_out      (read_command_out_full_region_latched                 ),
		.data_out_valid(read_command_out_full_region_valid                   )
	);

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_full_region[0].valid <= 0;
			read_command_out_full_region[1].valid <= 0;
			read_command_out_full_region[2].valid <= 0;
			read_command_out_full_region[3].valid <= 0;

			read_command_out_full_region[0].payload <= 0;
			read_command_out_full_region[1].payload <= 0;
			read_command_out_full_region[2].payload <= 0;
			read_command_out_full_region[3].payload <= 0;
		end else begin
			read_command_out_full_region[0].valid <= read_command_out_full_region_valid[0];
			read_command_out_full_region[1].valid <= read_command_out_full_region_valid[1];
			read_command_out_full_region[2].valid <= read_command_out_full_region_valid[2];
			read_command_out_full_region[3].valid <= read_command_out_full_region_valid[3];

			read_command_out_full_region[0].payload <= read_command_out_full_region_latched[0].payload;
			read_command_out_full_region[1].payload <= read_command_out_full_region_latched[1].payload;
			read_command_out_full_region[2].payload <= read_command_out_full_region_latched[2].payload;
			read_command_out_full_region[3].payload <= read_command_out_full_region_latched[3].payload;
		end
	end

////////////////////////////////////////////////////////////////////////////
// Caching logic
////////////////////////////////////////////////////////////////////////////

	cu_vertex_cache_resue_module #(
		.NUM_READ_REQUESTS(NUM_READ_REQUESTS),
		.NUM_CACHE_ENTRIES(NUM_CACHE_ENTRIES)
	) cu_vertex_cache_resue_module_3_instant (
		.clock             (clock                            ),
		.rstn_in           (rstn_internal                    ),
		.enabled_in        (enabled                          ),
		.wed_request_in    (wed_request_in_latched           ),
		.read_response_in  (response_data_edge_data_region[3]),
		.read_data_0_in    (read_data_0_edge_data_region[3]  ),
		.read_data_1_in    (read_data_1_edge_data_region[3]  ),
		.read_buffer_status(command_buffer_status[4]         ),
		.cu_configure      (cu_configure_latched             ),
		.read_command_in   (read_command_out_full_region[3] ),
		.read_command_out  (read_command_out_cache_full[3]   ),
		.read_response_out (read_response_out_edge_data[3]   ),
		.read_data_0_out   (read_data_0_out_edge_data[3]     ),
		.read_data_1_out   (read_data_1_out_edge_data[3]     )
	);

	cu_vertex_cache_resue_module #(
		.NUM_READ_REQUESTS(NUM_READ_REQUESTS),
		.NUM_CACHE_ENTRIES(NUM_CACHE_ENTRIES)
	) cu_vertex_cache_resue_module_2_instant (
		.clock             (clock                            ),
		.rstn_in           (rstn_internal                    ),
		.enabled_in        (enabled                          ),
		.wed_request_in    (wed_request_in_latched           ),
		.read_response_in  (response_data_edge_data_region[2]),
		.read_data_0_in    (read_data_0_edge_data_region[2]  ),
		.read_data_1_in    (read_data_1_edge_data_region[2]  ),
		.read_buffer_status(command_buffer_status[3]         ),
		.cu_configure      (cu_configure_latched             ),
		.read_command_in   (read_command_out_full_region[2]  ),
		.read_command_out  (read_command_out_cache_full[2]   ),
		.read_response_out (read_response_out_edge_data[2]   ),
		.read_data_0_out   (read_data_0_out_edge_data[2]     ),
		.read_data_1_out   (read_data_1_out_edge_data[2]     )
	);

	cu_vertex_cache_resue_module #(
		.NUM_READ_REQUESTS(NUM_READ_REQUESTS),
		.NUM_CACHE_ENTRIES(NUM_CACHE_ENTRIES)
	) cu_vertex_cache_resue_module_1_instant (
		.clock             (clock                            ),
		.rstn_in           (rstn_internal                    ),
		.enabled_in        (enabled                          ),
		.wed_request_in    (wed_request_in_latched           ),
		.read_response_in  (response_data_edge_data_region[1]),
		.read_data_0_in    (read_data_0_edge_data_region[1]  ),
		.read_data_1_in    (read_data_1_edge_data_region[1]  ),
		.read_buffer_status(command_buffer_status[2]         ),
		.cu_configure      (cu_configure_latched             ),
		.read_command_in   (read_command_out_full_region[1] ),
		.read_command_out  (read_command_out_cache_full[1]   ),
		.read_response_out (read_response_out_edge_data[1]   ),
		.read_data_0_out   (read_data_0_out_edge_data[1]     ),
		.read_data_1_out   (read_data_1_out_edge_data[1]     )
	);

	cu_vertex_cache_resue_module #(
		.NUM_READ_REQUESTS(NUM_READ_REQUESTS),
		.NUM_CACHE_ENTRIES(NUM_CACHE_ENTRIES)
	) cu_vertex_cache_resue_module_0_instant (
		.clock             (clock                            ),
		.rstn_in           (rstn_internal                    ),
		.enabled_in        (enabled                          ),
		.wed_request_in    (wed_request_in_latched           ),
		.read_response_in  (response_data_edge_data_region[0]),
		.read_data_0_in    (read_data_0_edge_data_region[0]  ),
		.read_data_1_in    (read_data_1_edge_data_region[0]  ),
		.read_buffer_status(command_buffer_status[1]         ),
		.cu_configure      (cu_configure_latched             ),
		.read_command_in   (read_command_out_full_region[0] ),
		.read_command_out  (read_command_out_cache_full[0]   ),
		.read_response_out (read_response_out_edge_data[0]   ),
		.read_data_0_out   (read_data_0_out_edge_data[0]     ),
		.read_data_1_out   (read_data_1_out_edge_data[0]     )
	);

endmodule