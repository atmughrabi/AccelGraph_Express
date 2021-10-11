
// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_control.sv
// Create : 2021-10-11 06:48:04
// Revise : 2021-10-11 06:48:06
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_control #(
	parameter NUM_READ_REQUESTS                        = 2                   ,
	parameter NUM_GRAPH_CU                             = NUM_GRAPH_CU_GLOBAL ,
	parameter NUM_VERTEX_CU                            = NUM_VERTEX_CU_GLOBAL
) (
	input  logic              clock                       , // Clock
	input  logic              rstn_in                     ,
	input  logic              enabled_in                  ,
	input  WEDInterface       wed_request_in              ,
	input  ResponseBufferLine read_response_in            ,
	input  ResponseBufferLine prefetch_read_response_in   ,
	input  ResponseBufferLine prefetch_write_response_in  ,
	input  ResponseBufferLine write_response_in           ,
	input  ReadWriteDataLine  read_data_0_in              ,
	input  ReadWriteDataLine  read_data_1_in              ,
	input  BufferStatus       read_buffer_status          ,
	input  BufferStatus       prefetch_read_buffer_status ,
	input  BufferStatus       prefetch_write_buffer_status,
	input  BufferStatus       write_buffer_status         ,
	input  cu_configure_type  cu_configure                ,
	output cu_return_type     cu_return                   ,
	output logic              cu_done                     ,
	output logic [0:63]       cu_status                   ,
	output CommandBufferLine  read_command_out            ,
	output CommandBufferLine  prefetch_read_command_out   ,
	output CommandBufferLine  prefetch_write_command_out  ,
	output CommandBufferLine  write_command_out           ,
	output ReadWriteDataLine  write_data_0_out            ,
	output ReadWriteDataLine  write_data_1_out
);


	logic rstn_internal;
	logic enabled      ;

////////////////////////////////////////////////////////////////////////////
// Input
////////////////////////////////////////////////////////////////////////////

	WEDInterface       wed_request_in_latched              ;
	ResponseBufferLine read_response_in_latched            ;
	ResponseBufferLine prefetch_read_response_in_latched   ;
	ResponseBufferLine prefetch_write_response_in_latched  ;
	ResponseBufferLine write_response_in_latched           ;
	ReadWriteDataLine  read_data_0_in_latched              ;
	ReadWriteDataLine  read_data_1_in_latched              ;
	BufferStatus       read_buffer_status_latched          ;
	BufferStatus       prefetch_read_buffer_status_latched ;
	BufferStatus       prefetch_write_buffer_status_latched;
	BufferStatus       write_buffer_status_latched         ;
	cu_configure_type  cu_configure_latched                ;

////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////

	cu_return_type    cu_return_latched                 ;
	logic             cu_done_latched                   ;
	logic [0:63]      cu_status_latched                 ;
	CommandBufferLine read_command_out_latched          ;
	CommandBufferLine prefetch_read_command_out_latched ;
	CommandBufferLine prefetch_write_command_out_latched;
	CommandBufferLine write_command_out_latched         ;
	ReadWriteDataLine write_data_0_out_latched          ;
	ReadWriteDataLine write_data_1_out_latched          ;

////////////////////////////////////////////////////////////////////////////
// logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_in) begin
		if(~rstn_in) begin
			rstn_internal                              <= 0;
		end else begin
			rstn_internal                              <= rstn_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//enable logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			enabled                                    <= 0;
		end else begin
			enabled                                    <= enabled_in;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive input
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			wed_request_in_latched.valid               <= 0;
			read_response_in_latched.valid             <= 0;
			prefetch_read_response_in_latched.valid    <= 0;
			prefetch_write_response_in_latched.valid   <= 0;
			write_response_in_latched.valid            <= 0;
			read_data_0_in_latched.valid               <= 0;
			read_data_1_in_latched.valid               <= 0;

			read_buffer_status_latched                 <= 0;
			prefetch_read_buffer_status_latched        <= 0;
			prefetch_write_buffer_status_latched       <= 0;
			write_buffer_status_latched                <= 0;

			read_buffer_status_latched.empty           <= 1;
			prefetch_read_buffer_status_latched.empty  <= 1;
			prefetch_write_buffer_status_latched.empty <= 1;
			write_buffer_status_latched.empty          <= 1;

			cu_configure_latched                       <= 0;
		end else begin
			wed_request_in_latched.valid               <= wed_request_in.valid;
			read_response_in_latched.valid             <= read_response_in.valid;
			prefetch_read_response_in_latched.valid    <= prefetch_read_response_in.valid;
			prefetch_write_response_in_latched.valid   <= prefetch_write_response_in.valid;
			write_response_in_latched.valid            <= write_response_in.valid;
			read_data_0_in_latched.valid               <= read_data_0_in.valid ;
			read_data_1_in_latched.valid               <= read_data_1_in.valid;

			read_buffer_status_latched                 <= read_buffer_status;
			prefetch_read_buffer_status_latched        <= prefetch_read_buffer_status;
			prefetch_write_buffer_status_latched       <= prefetch_write_buffer_status;
			write_buffer_status_latched                <= write_buffer_status;

			cu_configure_latched                       <= cu_configure;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			wed_request_in_latched.payload             <= 0;
			read_response_in_latched.payload           <= 0;
			prefetch_read_response_in_latched.payload  <= 0;
			prefetch_write_response_in_latched.payload <= 0;
			write_response_in_latched.payload          <= 0;
			read_data_0_in_latched.payload             <= 0;
			read_data_1_in_latched.payload             <= 0;
		end else begin
			wed_request_in_latched.payload             <= wed_request_in.payload;
			read_response_in_latched.payload           <= read_response_in.payload;
			prefetch_read_response_in_latched.payload  <= prefetch_read_response_in.payload;
			prefetch_write_response_in_latched.payload <= prefetch_write_response_in.payload;
			write_response_in_latched.payload          <= write_response_in.payload;
			read_data_0_in_latched.payload             <= read_data_0_in.payload ;
			read_data_1_in_latched.payload             <= read_data_1_in.payload;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Drive output
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			cu_return                                  <= 0;
			cu_done                                    <= 0;
			cu_status                                  <= 0;
			read_command_out.valid                     <= 0;
			prefetch_read_command_out.valid            <= 0;
			prefetch_write_command_out.valid           <= 0;
			write_command_out.valid                    <= 0;
			write_data_0_out.valid                     <= 0;
			write_data_1_out.valid                     <= 0;
		end else begin
			if(enabled)begin
				cu_return                              <= cu_return_latched;
				cu_done                                <= cu_done_latched;
				cu_status                              <= cu_status_latched;
				read_command_out.valid                 <= read_command_out_latched.valid;
				prefetch_read_command_out.valid        <= prefetch_read_command_out_latched.valid;
				prefetch_write_command_out.valid       <= prefetch_write_command_out_latched.valid;
				write_command_out.valid                <= write_command_out_latched.valid;
				write_data_0_out.valid                 <= write_data_0_out_latched.valid;
				write_data_1_out.valid                 <= write_data_1_out_latched.valid;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out.payload                   <= 0;
			prefetch_read_command_out.payload          <= 0;
			prefetch_write_command_out.payload         <= 0;
			write_command_out.payload                  <= 0;
			write_data_0_out.payload                   <= 0;
			write_data_1_out.payload                   <= 0;
		end else begin
			read_command_out.payload                   <= read_command_out_latched.payload;
			prefetch_read_command_out.payload          <= prefetch_read_command_out_latched.payload;
			prefetch_write_command_out.payload         <= prefetch_write_command_out_latched.payload;
			write_command_out.payload                  <= write_command_out_latched.payload;
			write_data_0_out.payload                   <= write_data_0_out_latched.payload;
			write_data_1_out.payload                   <= write_data_1_out_latched.payload;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Compute Units
////////////////////////////////////////////////////////////////////////////


	cu_graph_algorithm_cu_clusters_control cu_graph_algorithm_cu_clusters_control_instant (
		.clock                       (clock                               ),
		.rstn_in                     (rstn_internal                       ),
		.enabled_in                  (enabled                             ),
		.wed_request_in              (wed_request_in_latched              ),
		.read_response_in            (read_response_in_latched            ),
		.prefetch_read_response_in   (prefetch_read_response_in_latched   ),
		.prefetch_write_response_in  (prefetch_write_response_in_latched  ),
		.write_response_in           (write_response_in_latched           ),
		.read_data_0_in              (read_data_0_in_latched              ),
		.read_data_1_in              (read_data_1_in_latched              ),
		.read_buffer_status          (read_buffer_status_latched          ),
		.prefetch_read_buffer_status (prefetch_read_buffer_status_latched ),
		.prefetch_write_buffer_status(prefetch_write_buffer_status_latched),
		.write_buffer_status         (write_buffer_status_latched         ),
		.cu_configure                (cu_configure_latched                ),
		.cu_return                   (cu_return_latched                   ),
		.cu_done                     (cu_done_latched                     ),
		.cu_status                   (cu_status_latched                   ),
		.read_command_out            (read_command_out_latched            ),
		.prefetch_read_command_out   (prefetch_read_command_out_latched   ),
		.prefetch_write_command_out  (prefetch_write_command_out_latched  ),
		.write_command_out           (write_command_out_latched           ),
		.write_data_0_out            (write_data_0_out_latched            ),
		.write_data_1_out            (write_data_1_out_latched            )
	);


////////////////////////////////////////////////////////////////////////////
//Cache Reuse Unit
////////////////////////////////////////////////////////////////////////////

	cu_vertex_cache_reuse_control #(
		.NUM_READ_REQUESTS(NUM_READ_REQUESTS),
		.NUM_GRAPH_CU(NUM_GRAPH_CU),
		.NUM_VERTEX_CU(NUM_VERTEX_CU)
	) inst_cu_vertex_cache_reuse_control (
		.clock              (clock),
		.rstn_in            (rstn_in),
		.enabled_in         (enabled_in),
		.wed_request_in     (wed_request_in),
		.read_response_in   (read_response_in),
		.read_data_0_in     (read_data_0_in),
		.read_data_1_in     (read_data_1_in),
		.read_buffer_status (read_buffer_status),
		.cu_configure       (cu_configure),
		.read_command_in    (read_command_in),
		.read_command_out   (read_command_out),
		.read_response_out  (read_response_out),
		.read_data_0_out    (read_data_0_out),
		.read_data_1_out    (read_data_1_out)
	);


endmodule