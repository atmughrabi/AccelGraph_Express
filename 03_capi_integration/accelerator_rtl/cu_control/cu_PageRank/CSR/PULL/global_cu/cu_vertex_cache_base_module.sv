// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_cache_base_module.sv
// Create : 2021-10-20 18:45:25
// Revise : 2021-10-21 23:16:25
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_cache_base_module (
	input  logic              clock             ,
	input  logic              rstn_in           ,
	input  logic              enabled_in        ,
	input  EdgeDataRead       edge_data_variable,
	input  CommandBufferLine  read_command_in   ,
	output CommandBufferLine  read_command_out  ,
	output ResponseBufferLine read_response_out ,
	output ReadWriteDataLine  read_data_0_out   ,
	output ReadWriteDataLine  read_data_1_out
);

////////////////////////////////////////////////////////////////////////////
// Cache parameters
////////////////////////////////////////////////////////////////////////////

	parameter VERTEX_CACHE_ENTRIES_NUM = 64                                          ;
	parameter VERTEX_CACHE_INDEX_BITS  = $clog2(VERTEX_CACHE_ENTRIES_NUM)            ;
	parameter VERTEX_CACHE_TAG_BITS    = (VERTEX_SIZE_BITS - VERTEX_CACHE_INDEX_BITS);
	parameter VERTEX_CACHE_DATA_BITS   = $bits(EdgeDataRead)                         ;

////////////////////////////////////////////////////////////////////////////
// General Internal reset/enable signals
////////////////////////////////////////////////////////////////////////////

	integer i            ;
	logic   rstn_internal;
	logic   enabled      ;

////////////////////////////////////////////////////////////////////////////
// Cache Memory Registers
////////////////////////////////////////////////////////////////////////////

	logic                                 reg_CACHE_TAG_VALID  ;
	logic                                 reg_CACHE_DATA_VALID ;
	logic [0:(VERTEX_CACHE_INDEX_BITS-1)] reg_CACHE_INDEX_read ;
	logic [0:(VERTEX_CACHE_INDEX_BITS-1)] reg_CACHE_INDEX_write;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG        ;
	logic [ 0:(VERTEX_CACHE_DATA_BITS-1)] reg_CACHE_DATA       ;

////////////////////////////////////////////////////////////////////////////
// General Internal Registers
////////////////////////////////////////////////////////////////////////////

	logic                                reg_DATA_VARIABLE_valid      ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_DATA_VARIABLE_0          ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_DATA_VARIABLE_1          ;
	EdgeDataRead                         edge_data_variable_reg       ;
	ReadWriteDataLine                    read_data_0_out_reg          ;
	ReadWriteDataLine                    read_data_1_out_reg          ;
	ResponseBufferLine                   read_response_out_reg        ;
	CommandBufferLine                    read_command_in_latched_reg  ;
	CommandBufferLine                    read_command_in_latched_reg_2;

////////////////////////////////////////////////////////////////////////////
// Input
////////////////////////////////////////////////////////////////////////////

	EdgeDataRead      edge_data_variable_latched;
	CommandBufferLine read_command_in_latched   ;

////////////////////////////////////////////////////////////////////////////
// Output
////////////////////////////////////////////////////////////////////////////

	CommandBufferLine  read_command_out_latched ;
	ResponseBufferLine read_response_out_latched;
	ReadWriteDataLine  read_data_0_out_latched  ;
	ReadWriteDataLine  read_data_1_out_latched  ;

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
			edge_data_variable_latched.valid <= 0;
			read_command_in_latched.valid    <= 0;
		end else begin
			edge_data_variable_latched.valid <= edge_data_variable.valid;
			read_command_in_latched.valid    <= read_command_in.valid;
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			edge_data_variable_latched.payload <= 0;
			read_command_in_latched.payload    <= 0;
		end else begin
			edge_data_variable_latched.payload <= edge_data_variable.payload;
			read_command_in_latched.payload    <= read_command_in.payload;
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



	assign read_response_out_latched = read_response_out_reg;
	assign read_data_0_out_latched   = read_data_0_out_reg;
	assign read_data_1_out_latched   = read_data_1_out_reg;

////////////////////////////////////////////////////////////////////////////
//Construct Data Cachelines and Response Packets
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			edge_data_variable_reg.valid <= 0;
		end else begin
			if(edge_data_variable_latched.valid)begin
				edge_data_variable_reg.valid <= edge_data_variable_latched.valid;
			end else begin
				edge_data_variable_reg.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		edge_data_variable_reg.payload.cu_id_x <= edge_data_variable_latched.payload.cu_id_x;
		edge_data_variable_reg.payload.cu_id_y <= edge_data_variable_latched.payload.cu_id_y;
		edge_data_variable_reg.payload.data    <= swap_endianness_data_read(edge_data_variable_latched.payload.data);
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			reg_DATA_VARIABLE_valid <= 0;
		end else begin
			if(edge_data_variable_reg.valid)begin
				reg_DATA_VARIABLE_valid <= edge_data_variable_reg.valid;
			end else begin
				reg_DATA_VARIABLE_valid <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		for (i = 0; i < CACHELINE_DATA_READ_NUM_HF; i++) begin
			reg_DATA_VARIABLE_0[DATA_SIZE_READ_BITS*i+:DATA_SIZE_READ_BITS] <= edge_data_variable_reg.payload.data;
			reg_DATA_VARIABLE_1[DATA_SIZE_READ_BITS*i+:DATA_SIZE_READ_BITS] <= edge_data_variable_reg.payload.data;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Cache Read Command Logic
////////////////////////////////////////////////////////////////////////////

	logic                                 reg_CACHE_TAG_VALID  ;
	logic                                 reg_CACHE_DATA_VALID ;
	logic [0:(VERTEX_CACHE_INDEX_BITS-1)] reg_CACHE_INDEX_read ;
	logic [0:(VERTEX_CACHE_INDEX_BITS-1)] reg_CACHE_INDEX_write;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG        ;
	logic [ 0:(VERTEX_CACHE_DATA_BITS-1)] reg_CACHE_DATA       ;

	assign read_command_out_latched = read_command_in_latched;

		always_ff @(posedge clock or negedge rstn_internal) begin
			if(~rstn_internal) begin
				reg_CACHE_TAG_VALID  <= 0;
				reg_CACHE_DATA_VALID <= 0;
				reg_CACHE_INDEX_read      <= 0;
				reg_CACHE_INDEX_write        <= 0;
				reg_CACHE_TAG       <= 0;
				reg_CACHE_DATA       <= 0;
			end else begin
				if(read_command_in_latched.valid)begin
					reg_CACHE_INDEX_read <= read_command_in_latched.payload.cmd.address_offset;
				end else begin
					reg_CACHE_TAG_VALID  <= 0;
					reg_CACHE_DATA_VALID <= 0;
					reg_CACHE_INDEX_read      <= 0;
					reg_CACHE_INDEX_write        <= 0;
					reg_CACHE_TAG       <= 0;
					reg_CACHE_DATA       <= 0;
				end
			end
		end



////////////////////////////////////////////////////////////////////////////
//Cache blocks
////////////////////////////////////////////////////////////////////////////

	// ram #(
	// 	.WIDTH(VERTEX_CACHE_TAG_BITS),
	// 	.DEPTH(VERTEX_CACHE_ENTRIES_NUM)
	// ) ram1_cache_tag_array_instant (
	// 	.clock   (clock    ),
	// 	.we      (we       ),
	// 	.wr_addr (wr_addr  ),
	// 	.data_in (data_in  ),

	// 	.rd_addr (rd_addr1 ),
	// 	.data_out(data_out1)
	// );


	// ram #(
	// 	.WIDTH($bits(CommandBufferLine)),
	// 	.DEPTH(DEPTH                   )
	// ) ram_cache_vertex_data_hot_array_instant (
	// 	.clock   (clock    ),
	// 	.we      (we       ),
	// 	.wr_addr (wr_addr  ),
	// 	.data_in (data_in  ),

	// 	.rd_addr (rd_addr1 ),
	// 	.data_out(data_out1)
	// );

endmodule