// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2021 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : array_struct_type_filter_vertex_criterion_demux_bus.sv
// Create : 2021-10-25 02:57:07
// Revise : 2021-10-25 04:53:31
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

import CU_PKG::*;
import GLOBALS_CU_PKG::*;

module array_struct_type_filter_vertex_criterion_demux_bus #(
	parameter DATA_WIDTH = 32,
	parameter BUS_WIDTH  = 4 ,
	parameter SEL_WIDTH  = 32
) (
	input  logic                  clock                         ,
	input  logic                  rstn                          ,
	input  logic [ 0:SEL_WIDTH-1] sel_in                        ,
	input  logic [0:DATA_WIDTH-1] data_in                       ,
	input  logic                  data_in_valid                 ,
	output logic [0:DATA_WIDTH-1] data_out [0:BUS_WIDTH-1]      ,
	output logic                  data_out_valid [0:BUS_WIDTH-1]
);

	logic [0:SEL_WIDTH-1] sel_in_internal                       ;
	logic [      0:DATA_WIDTH-1] data_in_internal                      ;
	logic                        data_in_valid_internal                ;
	logic                        data_out_valid_internal[0:BUS_WIDTH-1];
	logic [      0:DATA_WIDTH-1] data_out_internal      [0:BUS_WIDTH-1];

	////////////////////////////////////////////////////////////////////////////
	//latche logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_in_valid_internal <= 0;
			sel_in_internal        <= STRUCT_INVALID;
		end else begin
			data_in_valid_internal <= data_in_valid;
			sel_in_internal        <= sel_in;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_in_internal <= 0;
		end else begin
			data_in_internal <= data_in;
		end
	end

	////////////////////////////////////////////////////////////////////////////
	//demux logic
	////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_out_valid_internal[0] <= 0;
			data_out_valid_internal[1] <= 0;
			data_out_valid_internal[2] <= 0;
			data_out_valid_internal[3] <= 0;
		end else begin
			case (sel_in_internal)
				VERTEX_VALUE_HOT_U32 : begin
					data_out_valid_internal[0] <= 0;
					data_out_valid_internal[1] <= 0;
					data_out_valid_internal[2] <= 0;
					data_out_valid_internal[3] <= data_in_valid_internal;
				end
				VERTEX_CACHE_WARM_U32 : begin
					data_out_valid_internal[0] <= 0;
					data_out_valid_internal[1] <= data_in_valid_internal;
					data_out_valid_internal[2] <= 0;
					data_out_valid_internal[3] <= 0;
				end
				VERTEX_VALUE_LUKEWARM_U32 : begin
					data_out_valid_internal[0] <= 0;
					data_out_valid_internal[1] <= 0;
					data_out_valid_internal[2] <= data_in_valid_internal;
					data_out_valid_internal[3] <= 0;
				end
				default : begin
					data_out_valid_internal[0] <= data_in_valid_internal;
					data_out_valid_internal[1] <= 0;
					data_out_valid_internal[2] <= 0;
					data_out_valid_internal[3] <= 0;
				end
			endcase
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_out_internal[0] <= 0;
			data_out_internal[1] <= 0;
			data_out_internal[2] <= 0;
			data_out_internal[3] <= 0;
		end else begin
			data_out_internal[0] <= data_in_internal;
			data_out_internal[1] <= data_in_internal;
			data_out_internal[2] <= data_in_internal;
			data_out_internal[3] <= data_in_internal;
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			data_out[0]       <= 0;
			data_out[1]       <= 0;
			data_out[2]       <= 0;
			data_out[3]       <= 0;
			data_out_valid[0] <= 0;
			data_out_valid[1] <= 0;
			data_out_valid[2] <= 0;
			data_out_valid[3] <= 0;
		end else begin
			data_out[0]       <= data_out_internal[0];
			data_out[1]       <= data_out_internal[1];
			data_out[2]       <= data_out_internal[2];
			data_out[3]       <= data_out_internal[3];
			data_out_valid[0] <= data_out_valid_internal[0];
			data_out_valid[1] <= data_out_valid_internal[1];
			data_out_valid[2] <= data_out_valid_internal[2];
			data_out_valid[3] <= data_out_valid_internal[3];
		end
	end

endmodule
