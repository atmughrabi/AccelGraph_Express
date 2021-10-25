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
// Revise : 2021-10-25 03:37:38
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_cache_base_module #(parameter NUM_CACHE_ENTRIES = 8192) (
	input  logic              clock             ,
	input  logic              rstn_in           ,
	input  logic              enabled_in        ,
	input  EdgeDataCache      edge_data_variable,
	input  CommandBufferLine  read_command_in   ,
	output CommandBufferLine  read_command_out  ,
	output ResponseBufferLine read_response_out ,
	output ReadWriteDataLine  read_data_0_out   ,
	output ReadWriteDataLine  read_data_1_out
);

////////////////////////////////////////////////////////////////////////////
// Cache parameters
////////////////////////////////////////////////////////////////////////////

	parameter        VERTEX_CACHE_ENTRIES_NUM = NUM_CACHE_ENTRIES                                                     ;
	parameter        VERTEX_CACHE_INDEX_BITS  = $clog2(VERTEX_CACHE_ENTRIES_NUM)                                      ;
	parameter        VERTEX_CACHE_TAG_BITS    = (VERTEX_SIZE_BITS - VERTEX_CACHE_INDEX_BITS)                          ;
	parameter        VERTEX_CACHE_DATA_BITS   = $bits(EdgeDataCacheEntry)                                             ;
	parameter        RSP_DELAY                = 11                                                                    ;
	parameter [0:63] ADDRESS_INDEX_MASK       = {{(64-VERTEX_CACHE_INDEX_BITS){1'b0}},{VERTEX_CACHE_INDEX_BITS{1'b1}}};

////////////////////////////////////////////////////////////////////////////
// General Internal reset/enable signals
////////////////////////////////////////////////////////////////////////////

	integer i            ;
	genvar  j            ;
	logic   rstn_internal;
	logic   enabled      ;

////////////////////////////////////////////////////////////////////////////
// Cache Memory Registers
////////////////////////////////////////////////////////////////////////////

	logic                                 valid_data                ;
	logic                                 reg_CACHE_TAG_READ_VALID  ;
	logic                                 reg_CACHE_DATA_WRITE_VALID;
	logic [0:(VERTEX_CACHE_INDEX_BITS-1)] reg_CACHE_INDEX_read      ;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG_read        ;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG_read_2      ;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG_read_cmp    ;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG_read_cmp_2  ;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG_read_cmp_3  ;
	logic [ 0:(VERTEX_CACHE_DATA_BITS-1)] reg_CACHE_DATA_read       ;
	logic [0:(VERTEX_CACHE_INDEX_BITS-1)] reg_CACHE_INDEX_write     ;
	logic [  0:(VERTEX_CACHE_TAG_BITS-1)] reg_CACHE_TAG_write       ;
	logic [ 0:(VERTEX_CACHE_DATA_BITS-1)] reg_CACHE_DATA_write      ;

////////////////////////////////////////////////////////////////////////////
// General Internal Registers
////////////////////////////////////////////////////////////////////////////

	ResponseBufferLine                   response_control_out_latched_S[0:RSP_DELAY-1];
	logic                                reg_DATA_VARIABLE_valid                      ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_DATA_VARIABLE_0                          ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_DATA_VARIABLE_1                          ;
	EdgeDataCacheEntry                   edge_data_variable_reg                       ;
	ReadWriteDataLine                    read_data_0_out_reg                          ;
	ReadWriteDataLine                    read_data_1_out_reg                          ;
	ReadWriteDataLine                    read_data_1_out_reg_2                        ;
	ResponseBufferLine                   read_response_out_reg                        ;
	CommandBufferLine                    read_command_in_latched_reg                  ;
	CommandBufferLine                    read_command_in_latched_reg_2                ;
	CommandBufferLine                    read_command_in_latched_reg_3                ;
	CommandBufferLine                    read_command_in_latched_reg_4                ;

////////////////////////////////////////////////////////////////////////////
// Input
////////////////////////////////////////////////////////////////////////////

	EdgeDataCache     edge_data_variable_latched;
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



	// assign read_command_out_latched = read_command_in_latched;
	// assign read_response_out_latched = read_response_out_reg;
	assign read_data_0_out_latched = read_data_0_out_reg;
	assign read_data_1_out_latched = read_data_1_out_reg_2;

////////////////////////////////////////////////////////////////////////////
//Construct Data Cachelines and Response Packets
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_response_out_reg.valid <= 0;
			read_data_0_out_reg.valid   <= 0;
			read_data_1_out_reg.valid   <= 0;
		end else begin
			if(reg_DATA_VARIABLE_valid)begin
				read_response_out_reg.valid <= reg_DATA_VARIABLE_valid;
				read_data_0_out_reg.valid   <= reg_DATA_VARIABLE_valid;
				read_data_1_out_reg.valid   <= reg_DATA_VARIABLE_valid;
			end else begin
				read_response_out_reg.valid <= 0;
				read_data_0_out_reg.valid   <= 0;
				read_data_1_out_reg.valid   <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		read_response_out_reg.payload.cmd              <= read_command_in_latched_reg_4.payload.cmd ;
		read_response_out_reg.payload.response_credits <= 0 ;
		read_response_out_reg.payload.response         <= DONE;
		read_data_0_out_reg.payload.cmd                <= read_command_in_latched_reg_4.payload.cmd ;
		read_data_1_out_reg.payload.cmd                <= read_command_in_latched_reg_4.payload.cmd ;
		read_data_0_out_reg.payload.data               <= reg_DATA_VARIABLE_0 ;
		read_data_1_out_reg.payload.data               <= reg_DATA_VARIABLE_1 ;
		read_data_1_out_reg_2                          <= read_data_1_out_reg;
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			reg_DATA_VARIABLE_valid <= 0;
		end else begin
			if(valid_data)begin
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
//Response delay logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			response_control_out_latched_S[0].valid <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				response_control_out_latched_S[0] <= read_response_out_reg;
			end
		end
	end

	generate
		for ( j = 1; j < (RSP_DELAY); j++) begin : generate_response_delay
			always_ff @(posedge clock or negedge rstn_internal) begin
				if(~rstn_internal) begin
					response_control_out_latched_S[j].valid  <= 0;
				end else begin
					if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
						response_control_out_latched_S[j] <= response_control_out_latched_S[j-1];
					end
				end
			end
		end
	endgenerate

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_response_out_latched.valid <= 0;
		end else begin
			if(enabled) begin // cycle delay for responses to make sure data_out arrives and handled before
				read_response_out_latched <= response_control_out_latched_S[RSP_DELAY-1];
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Cache Data/Tag Read Logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			reg_CACHE_TAG_READ_VALID <= 0;
			reg_CACHE_INDEX_read     <= 0;
			reg_CACHE_TAG_read_cmp   <= 0;
		end else begin
			if(read_command_in_latched.valid)begin
				reg_CACHE_TAG_READ_VALID <= read_command_in_latched.valid;
				reg_CACHE_INDEX_read     <= (read_command_in_latched.payload.cmd.address_offset & ADDRESS_INDEX_MASK);
				reg_CACHE_TAG_read_cmp   <= (read_command_in_latched.payload.cmd.address_offset >> VERTEX_CACHE_INDEX_BITS);
			end else begin
				reg_CACHE_TAG_READ_VALID <= 0;
				reg_CACHE_INDEX_read     <= 0;
				reg_CACHE_TAG_read_cmp   <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin

		//cycle 1
		// reg_CACHE_INDEX_read        <= (read_command_in_latched.payload.cmd.address_offset & ADDRESS_INDEX_MASK);
		// reg_CACHE_TAG_read_cmp      <= (read_command_in_latched.payload.cmd.address_offset >> VERTEX_CACHE_INDEX_BITS);
		read_command_in_latched_reg <= read_command_in_latched;

		//cycle 2
		//get reg_CACHE_TAG_read value
		reg_CACHE_TAG_read_cmp_2      <= reg_CACHE_TAG_read_cmp;
		read_command_in_latched_reg_2 <= read_command_in_latched_reg;

		//cycle 3
		// drive values and compare
		edge_data_variable_reg        <= reg_CACHE_DATA_read;
		reg_CACHE_TAG_read_2          <= reg_CACHE_TAG_read;
		reg_CACHE_TAG_read_cmp_3      <= reg_CACHE_TAG_read_cmp_2;
		read_command_in_latched_reg_3 <= read_command_in_latched_reg_2;
		read_command_in_latched_reg_4 <= read_command_in_latched_reg_3;


	end


	assign valid_data = read_command_in_latched_reg_3.valid & edge_data_variable_reg.valid & (reg_CACHE_TAG_read_cmp_3 == reg_CACHE_TAG_read_2);


	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched.valid <= 0;
		end else begin
			if(~valid_data)begin
				read_command_out_latched.valid <= read_command_in_latched_reg_3.valid;
			end else begin
				read_command_out_latched.valid <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			read_command_out_latched.payload <= 0;
		end else begin
			read_command_out_latched.payload <= read_command_in_latched_reg_3.payload;
		end
	end


////////////////////////////////////////////////////////////////////////////
//Cache Data/Tag Write Logic
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn_internal) begin
		if(~rstn_internal) begin
			reg_CACHE_DATA_WRITE_VALID <= 0;
			reg_CACHE_INDEX_write      <= 0;
			reg_CACHE_TAG_write        <= 0;
		end else begin
			if(edge_data_variable_latched.valid)begin
				reg_CACHE_DATA_WRITE_VALID <= edge_data_variable_latched.valid;
				reg_CACHE_INDEX_write      <= (edge_data_variable_latched.payload.id & ADDRESS_INDEX_MASK);
				reg_CACHE_TAG_write        <= (edge_data_variable_latched.payload.id >> VERTEX_CACHE_INDEX_BITS);
			end else begin
				reg_CACHE_DATA_WRITE_VALID <= 0;
				reg_CACHE_INDEX_write      <= 0;
				reg_CACHE_TAG_write        <= 0;
			end
		end
	end

	always_ff @(posedge clock) begin
		reg_CACHE_DATA_write <= edge_data_variable_latched;
	end

////////////////////////////////////////////////////////////////////////////
//Cache blocks
////////////////////////////////////////////////////////////////////////////

	ram #(
		.WIDTH(VERTEX_CACHE_TAG_BITS   ),
		.DEPTH(VERTEX_CACHE_ENTRIES_NUM)
	) ram1_cache_tag_array_instant (
		.clock   (clock                     ),
		.we      (reg_CACHE_DATA_WRITE_VALID),
		.wr_addr (reg_CACHE_INDEX_write     ),
		.data_in (reg_CACHE_TAG_write       ),
		
		.rd_addr (reg_CACHE_INDEX_read      ),
		.data_out(reg_CACHE_TAG_read        )
	);


	ram #(
		.WIDTH(VERTEX_CACHE_DATA_BITS  ),
		.DEPTH(VERTEX_CACHE_ENTRIES_NUM)
	) ram_cache_vertex_data_array_instant (
		.clock   (clock                     ),
		.we      (reg_CACHE_DATA_WRITE_VALID),
		.wr_addr (reg_CACHE_INDEX_write     ),
		.data_in (reg_CACHE_DATA_write      ),
		
		.rd_addr (reg_CACHE_INDEX_read      ),
		.data_out(reg_CACHE_DATA_read       )
	);

endmodule