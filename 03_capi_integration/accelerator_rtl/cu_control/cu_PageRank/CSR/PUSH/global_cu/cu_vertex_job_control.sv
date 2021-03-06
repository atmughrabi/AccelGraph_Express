// -----------------------------------------------------------------------------
//
//		"ACCEL-GRAPH Shared Memory Accelerator Project"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi atmughrabi@gmail.com/atmughra@ncsu.edu
// File   : cu_vertex_job_control.sv
// Create : 2019-09-26 15:19:30
// Revise : 2019-11-08 10:50:37
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

import GLOBALS_AFU_PKG::*;
import GLOBALS_CU_PKG::*;
import CAPI_PKG::*;
import WED_PKG::*;
import AFU_PKG::*;
import CU_PKG::*;

module cu_vertex_job_control (
	input  logic              clock                   , // Clock
	input  logic              rstn                    ,
	input  logic              enabled_in              ,
	input  logic [0:63]       cu_configure            ,
	input  WEDInterface       wed_request_in          ,
	input  ResponseBufferLine read_response_in        ,
	input  ReadWriteDataLine  read_data_0_in          ,
	input  ReadWriteDataLine  read_data_1_in          ,
	input  BufferStatus       read_buffer_status      ,
	input  logic              vertex_request          ,
	input  logic              read_command_bus_grant  ,
	output logic              read_command_bus_request,
	output CommandBufferLine  read_command_out        ,
	output VertexInterface    vertex
);


	logic        read_command_bus_grant_latched     ;
	logic        read_command_bus_request_latched   ;
	logic        read_command_bus_grant_latched_S2  ;
	logic        read_command_bus_request_latched_S2;
	BufferStatus vertex_buffer_status               ;

	logic [0:CACHELINE_INT_COUNTER_BITS] shift_limit_0    ;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_limit_1    ;
	logic                                shift_limit_clear;
	logic [0:CACHELINE_INT_COUNTER_BITS] shift_counter    ;
	logic                                start_shift_hf_0 ;
	logic                                start_shift_hf_1 ;
	logic                                switch_shift_hf  ;
	logic                                push_shift       ;

	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_OUT_DEGREE_0;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_EDGES_IDX_0 ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_READ_DATA_0 ;

	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_OUT_DEGREE_1;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_EDGES_IDX_1 ;
	logic [0:(CACHELINE_SIZE_BITS_HF-1)] reg_READ_DATA_1 ;

	logic clear_data_ready      ;
	logic fill_vertex_job_buffer;
	logic zero_pass             ;

	//output latched
	VertexInterface   vertex_latched             ;
	CommandBufferLine read_command_out_latched   ;
	CommandBufferLine read_command_out_latched_S2;

	//input lateched
	WEDInterface       wed_request_in_latched     ;
	ResponseBufferLine read_response_in_latched   ;
	ResponseBufferLine read_response_in_latched_S1;
	ResponseBufferLine read_response_in_latched_S2;
	ReadWriteDataLine  read_data_0_in_latched     ;
	ReadWriteDataLine  read_data_1_in_latched     ;

	logic vertex_request_latched;

	CommandBufferLine read_command_vertex_job_latched   ;
	CommandBufferLine read_command_vertex_job_latched_S2;
	BufferStatus      read_buffer_status_internal       ;

	BufferStatus    vertex_buffer_burst_status;
	logic           vertex_buffer_burst_pop   ;
	VertexInterface vertex_burst_variable     ;

	// internal registers to track logic
	// Read/write commands require the size to be a power of 2 (1, 2, 4, 8, 16, 32,64, 128).
	logic                             send_request_ready         ;
	logic [                     0:63] vertex_next_offset         ;
	logic [   0:(VERTEX_SIZE_BITS-1)] vertex_num_counter         ;
	logic [   0:(VERTEX_SIZE_BITS-1)] vertex_id_counter          ;
	logic                             generate_read_command      ;
	logic                             setup_read_command         ;
	VertexInterface                   vertex_variable            ;
	logic [   0:(VERTEX_SIZE_BITS-1)] out_degree_data            ;
	logic [   0:(VERTEX_SIZE_BITS-1)] edges_idx_degree_data      ;
	logic [0:(DATA_SIZE_READ_BITS-1)] vertex_read_data           ;
	logic                             out_degree_data_ready      ;
	logic                             edges_idx_degree_data_ready;
	logic                             vertex_read_data_ready     ;


	vertex_struct_state current_state, next_state;
	logic               enabled             ;
	logic               enabled_cmd         ;
	logic [0:63]        cu_configure_latched;

	logic             read_command_bus_grant_latched_NLOCK          ;
	CommandBufferLine read_command_out_latched_NLOCK                ;
	CommandBufferLine read_command_out_latched_issue                ;
	CommandBufferLine read_command_edge_data_burst_out_latched      ;
	CommandBufferLine read_command_edge_data_burst_out_latched_NLOCK;
	BufferStatus       read_buffer_status_internal_NLOCK            ;


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
			vertex                      <= 0;
			read_command_out            <= 0;
			read_command_out_latched_S2 <= 0;
		end else begin
			if(enabled) begin
				vertex                      <= vertex_latched;
				read_command_out            <= read_command_out_latched_S2;
				read_command_out_latched_S2 <= read_command_out_latched;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//drive inputs
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			wed_request_in_latched      <= 0;
			read_response_in_latched    <= 0;
			read_response_in_latched_S1 <= 0;
			read_response_in_latched_S2 <= 0;
			read_data_0_in_latched      <= 0;
			read_data_1_in_latched      <= 0;
			cu_configure_latched        <= 0;
			vertex_request_latched      <= 0;

		end else begin
			if(enabled) begin
				wed_request_in_latched      <= wed_request_in;
				read_response_in_latched_S1 <= read_response_in;
				read_response_in_latched_S2 <= read_response_in_latched_S1;
				read_response_in_latched    <= read_response_in_latched_S2;
				read_data_0_in_latched      <= read_data_0_in;
				read_data_1_in_latched      <= read_data_1_in;
				vertex_request_latched      <= vertex_request;
				if((|cu_configure))
					cu_configure_latched <= cu_configure;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//1. Generate Read Commands to obtain vertex structural info
////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn)
			current_state <= SEND_VERTEX_RESET;
		else begin
			if(enabled) begin
				current_state <= next_state;
			end
		end
	end // always_ff @(posedge clock)

	always_comb begin
		next_state = current_state;
		case (current_state)
			SEND_VERTEX_RESET : begin
				if(wed_request_in_latched.valid && enabled_cmd)
					next_state = SEND_VERTEX_INIT;
				else
					next_state = SEND_VERTEX_RESET;
			end
			SEND_VERTEX_INIT : begin
				next_state = SEND_VERTEX_IDLE;
			end
			SEND_VERTEX_IDLE : begin
				if(send_request_ready)
					next_state = START_VERTEX_REQ;
				else
					next_state = SEND_VERTEX_IDLE;
			end
			START_VERTEX_REQ : begin
				next_state = CALC_VERTEX_REQ_SIZE;
			end
			CALC_VERTEX_REQ_SIZE : begin
				next_state = SEND_VERTEX_START;
			end
			SEND_VERTEX_START : begin
				next_state = SEND_VERTEX_OUT_DEGREE;
			end
			SEND_VERTEX_OUT_DEGREE : begin
				next_state = SEND_VERTEX_READ_DATA;
			end
			SEND_VERTEX_READ_DATA : begin
				next_state = SEND_VERTEX_EDGES_IDX;
			end
			SEND_VERTEX_EDGES_IDX : begin
				next_state = WAIT_VERTEX_DATA;
			end
			WAIT_VERTEX_DATA : begin
				if(fill_vertex_job_buffer)
					next_state = SHIFT_VERTEX_DATA_START;
				else
					next_state = WAIT_VERTEX_DATA;
			end
			SHIFT_VERTEX_DATA_START : begin
				next_state = SHIFT_VERTEX_DATA_0;
			end
			SHIFT_VERTEX_DATA_0 : begin
				if((shift_counter < shift_limit_0))
					next_state = SHIFT_VERTEX_DATA_0;
				else
					next_state = SHIFT_VERTEX_DATA_DONE_0;
			end
			SHIFT_VERTEX_DATA_DONE_0 : begin
				if(|shift_limit_1 || zero_pass)
					next_state = SHIFT_VERTEX_DATA_1;
				else
					next_state = SHIFT_VERTEX_DATA_DONE_1;
			end
			SHIFT_VERTEX_DATA_1 : begin
				if((shift_counter < shift_limit_1))
					next_state = SHIFT_VERTEX_DATA_1;
				else
					next_state = SHIFT_VERTEX_DATA_DONE_1;
			end
			SHIFT_VERTEX_DATA_DONE_1 : begin
				next_state = SEND_VERTEX_IDLE;
			end
		endcase
	end // always_comb

	always_ff @(posedge clock) begin
		case (current_state)
			SEND_VERTEX_RESET : begin
				read_command_vertex_job_latched <= 0;
				vertex_next_offset              <= 0;
				generate_read_command           <= 0;
				setup_read_command              <= 0;
				clear_data_ready                <= 1;
				shift_limit_clear               <= 1;
				start_shift_hf_0                <= 0;
				start_shift_hf_1                <= 0;
				switch_shift_hf                 <= 0;
				shift_counter                   <= 0;
			end
			SEND_VERTEX_INIT : begin
				read_command_vertex_job_latched <= 0;
				clear_data_ready                <= 0;
				shift_limit_clear               <= 0;
				setup_read_command              <= 1;
			end
			SEND_VERTEX_IDLE : begin
				read_command_vertex_job_latched <= 0;
				setup_read_command              <= 0;
				shift_limit_clear               <= 0;
				shift_counter                   <= 0;
			end
			START_VERTEX_REQ : begin
				read_command_vertex_job_latched <= 0;
				generate_read_command           <= 1;
				shift_limit_clear               <= 0;
			end
			CALC_VERTEX_REQ_SIZE : begin
				generate_read_command <= 0;
			end
			SEND_VERTEX_START : begin
				read_command_vertex_job_latched <= read_command_vertex_job_latched_S2;
			end
			SEND_VERTEX_OUT_DEGREE : begin
				read_command_vertex_job_latched.valid              <= 1'b1;
				read_command_vertex_job_latched.address            <= wed_request_in_latched.wed.vertex_out_degree + vertex_next_offset;
				read_command_vertex_job_latched.cmd.address_offset <= wed_request_in_latched.wed.vertex_out_degree + vertex_next_offset;
				read_command_vertex_job_latched.cmd.array_struct   <= OUT_DEGREE;
			end
			SEND_VERTEX_READ_DATA : begin
				read_command_vertex_job_latched.address            <= wed_request_in_latched.wed.auxiliary1 + vertex_next_offset;
				read_command_vertex_job_latched.cmd.address_offset <= wed_request_in_latched.wed.auxiliary1 + vertex_next_offset;
				read_command_vertex_job_latched.cmd.array_struct   <= READ_GRAPH_DATA;
			end
			SEND_VERTEX_EDGES_IDX : begin
				read_command_vertex_job_latched.address            <= wed_request_in_latched.wed.vertex_edges_idx + vertex_next_offset;
				read_command_vertex_job_latched.cmd.address_offset <= wed_request_in_latched.wed.vertex_edges_idx + vertex_next_offset;
				read_command_vertex_job_latched.cmd.array_struct   <= EDGES_IDX;
				vertex_next_offset                                 <= vertex_next_offset + CACHELINE_SIZE;
			end
			WAIT_VERTEX_DATA : begin
				read_command_vertex_job_latched <= 0;
				if(fill_vertex_job_buffer) begin
					clear_data_ready <= 1;
				end
			end
			SHIFT_VERTEX_DATA_START : begin
				clear_data_ready <= 0;
				start_shift_hf_0 <= 0;
				start_shift_hf_1 <= 0;
				switch_shift_hf  <= 0;
			end
			SHIFT_VERTEX_DATA_0 : begin
				start_shift_hf_0 <= 1;
				start_shift_hf_1 <= 0;
				switch_shift_hf  <= 0;
				shift_counter    <= shift_counter + 1;
			end
			SHIFT_VERTEX_DATA_DONE_0 : begin
				start_shift_hf_0 <= 0;
				start_shift_hf_1 <= 0;
				switch_shift_hf  <= 0;
				shift_counter    <= 0;
			end
			SHIFT_VERTEX_DATA_1 : begin
				start_shift_hf_0 <= 0;
				start_shift_hf_1 <= 1;
				switch_shift_hf  <= 1;
				shift_counter    <= shift_counter + 1;
			end
			SHIFT_VERTEX_DATA_DONE_1 : begin
				start_shift_hf_0  <= 0;
				start_shift_hf_1  <= 0;
				shift_limit_clear <= 1;
				switch_shift_hf   <= 0;
				shift_counter     <= 0;
			end
		endcase
	end // always_ff @(posedge clock)

////////////////////////////////////////////////////////////////////////////
//generate Vertex data offset
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_vertex_job_latched_S2 <= 0;
			vertex_num_counter                 <= 0;
		end else begin
			if(setup_read_command)
				vertex_num_counter <= wed_request_in_latched.wed.num_vertices;

			if (generate_read_command) begin
				if(vertex_num_counter > CACHELINE_VERTEX_NUM)begin
					vertex_num_counter                                     <= vertex_num_counter - CACHELINE_VERTEX_NUM;
					read_command_vertex_job_latched_S2.cmd.real_size       <= CACHELINE_VERTEX_NUM;
					read_command_vertex_job_latched_S2.cmd.real_size_bytes <= 128;
					read_command_vertex_job_latched_S2.size                <= 12'h080;
					read_command_vertex_job_latched_S2.cmd.size            <= 12'h080;

					if (cu_configure_latched[3]) begin
						read_command_vertex_job_latched_S2.command <= READ_CL_S;
					end else begin
						read_command_vertex_job_latched_S2.command <= READ_CL_NA;
					end

				end
				else if (vertex_num_counter <= CACHELINE_VERTEX_NUM) begin
					vertex_num_counter                                     <= 0;
					read_command_vertex_job_latched_S2.cmd.real_size       <= vertex_num_counter;
					read_command_vertex_job_latched_S2.cmd.real_size_bytes <= (vertex_num_counter << $clog2(VERTEX_SIZE));

					if (cu_configure_latched[3]) begin
						read_command_vertex_job_latched_S2.command  <= READ_CL_S;
						read_command_vertex_job_latched_S2.size     <= 12'h080;
						read_command_vertex_job_latched_S2.cmd.size <= 12'h080;
					end else begin
						read_command_vertex_job_latched_S2.command  <= READ_PNA;
						read_command_vertex_job_latched_S2.size     <= cmd_size_calculate(vertex_num_counter);
						read_command_vertex_job_latched_S2.cmd.size <= cmd_size_calculate(vertex_num_counter);
					end
				end

				read_command_vertex_job_latched_S2.cmd.cu_id            <= VERTEX_CONTROL_ID;
				read_command_vertex_job_latched_S2.cmd.cmd_type         <= CMD_READ;
				read_command_vertex_job_latched_S2.cmd.cacheline_offset <= 0;

				read_command_vertex_job_latched_S2.cmd.abt <= map_CABT(cu_configure_latched[0:2]);
				read_command_vertex_job_latched_S2.abt     <= map_CABT(cu_configure_latched[0:2]);
			end else
			read_command_vertex_job_latched_S2 <= 0;
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex data into registers
////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			reg_OUT_DEGREE_0 <= 0;
			reg_EDGES_IDX_0  <= 0;
			reg_READ_DATA_0  <= 0;
		end else begin
			if(enabled_cmd && read_data_0_in_latched.valid) begin
				case (read_data_0_in_latched.cmd.array_struct)
					OUT_DEGREE : begin
						reg_OUT_DEGREE_0 <= read_data_0_in_latched;
					end
					EDGES_IDX : begin
						reg_EDGES_IDX_0 <= read_data_0_in_latched;
					end
					READ_GRAPH_DATA : begin
						reg_READ_DATA_0 <= read_data_0_in_latched;
					end
				endcase
			end

			if(~switch_shift_hf && start_shift_hf_0) begin
				reg_OUT_DEGREE_0 <= {reg_OUT_DEGREE_0[VERTEX_SIZE_BITS:(CACHELINE_SIZE_BITS_HF-1)],VERTEX_NULL_BITS};
				reg_EDGES_IDX_0  <= {reg_EDGES_IDX_0[VERTEX_SIZE_BITS:(CACHELINE_SIZE_BITS_HF-1)],VERTEX_NULL_BITS};
				reg_READ_DATA_0  <= {reg_READ_DATA_0[DATA_SIZE_READ_BITS:(CACHELINE_SIZE_BITS_HF-1)],DATA_READ_NULL_BITS};
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			reg_OUT_DEGREE_1 <= 0;
			reg_EDGES_IDX_1  <= 0;
			reg_READ_DATA_1  <= 0;
		end else begin
			if(enabled_cmd && read_data_1_in_latched.valid) begin
				case (read_data_1_in_latched.cmd.array_struct)
					OUT_DEGREE : begin
						reg_OUT_DEGREE_1 <= read_data_1_in_latched;
					end
					EDGES_IDX : begin
						reg_EDGES_IDX_1 <= read_data_1_in_latched;
					end
					READ_GRAPH_DATA : begin
						reg_READ_DATA_1 <= read_data_1_in_latched;
					end
				endcase
			end

			if(switch_shift_hf && start_shift_hf_1) begin
				reg_OUT_DEGREE_1 <= {reg_OUT_DEGREE_1[VERTEX_SIZE_BITS:(CACHELINE_SIZE_BITS_HF-1)],VERTEX_NULL_BITS};
				reg_EDGES_IDX_1  <= {reg_EDGES_IDX_1[VERTEX_SIZE_BITS:(CACHELINE_SIZE_BITS_HF-1)],VERTEX_NULL_BITS};
				reg_READ_DATA_1  <= {reg_READ_DATA_1[DATA_SIZE_READ_BITS:(CACHELINE_SIZE_BITS_HF-1)],DATA_READ_NULL_BITS};
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			out_degree_data_ready       <= 0;
			edges_idx_degree_data_ready <= 0;
			vertex_read_data_ready      <= 0;
		end else begin
			if(enabled_cmd && read_response_in_latched.valid && read_response_in_latched.response != NLOCK) begin
				case (read_response_in_latched.cmd.array_struct)
					OUT_DEGREE : begin
						out_degree_data_ready <= 1;
					end
					EDGES_IDX : begin
						edges_idx_degree_data_ready <= 1;
					end
					READ_GRAPH_DATA : begin
						vertex_read_data_ready <= 1;
					end
				endcase
			end

			if(clear_data_ready) begin
				out_degree_data_ready       <= 0;
				edges_idx_degree_data_ready <= 0;
				vertex_read_data_ready      <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			shift_limit_0 <= 0;
			shift_limit_1 <= 0;
			zero_pass     <= 0;
		end else begin
			if(enabled_cmd && read_response_in_latched.valid) begin
				if(~(|shift_limit_0) && ~shift_limit_clear) begin
					if(read_response_in_latched.cmd.real_size > CACHELINE_VERTEX_NUM_HF) begin
						shift_limit_0 <= CACHELINE_VERTEX_NUM_HF-1;
						shift_limit_1 <= read_response_in_latched.cmd.real_size - CACHELINE_VERTEX_NUM_HF - 1;
						zero_pass     <= ((read_response_in_latched.cmd.real_size - CACHELINE_EDGE_NUM_HF) == 1);
					end else begin
						shift_limit_0 <= read_response_in_latched.cmd.real_size-1;
						shift_limit_1 <= 0;
						zero_pass     <= 0;
					end
				end
			end

			if(shift_limit_clear) begin
				shift_limit_0 <= 0;
				shift_limit_1 <= 0;
				zero_pass     <= 0;
			end
		end
	end

////////////////////////////////////////////////////////////////////////////
//Read Vertex registers into vertex job queue
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//Buffers Vertices
////////////////////////////////////////////////////////////////////////////

	assign send_request_ready     = read_buffer_status_internal.empty && vertex_buffer_burst_status.empty  && (|vertex_num_counter) && wed_request_in_latched.valid;
	assign fill_vertex_job_buffer = out_degree_data_ready && edges_idx_degree_data_ready && vertex_read_data_ready;

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			vertex_variable   <= 0;
			vertex_id_counter <= 0;
		end
		else begin
			if(push_shift) begin
				vertex_id_counter          <= vertex_id_counter+1;
				vertex_variable.valid      <= push_shift;
				vertex_variable.id         <= vertex_id_counter;
				vertex_variable.out_degree <= swap_endianness_vertex_read(out_degree_data);
				vertex_variable.edges_idx  <= swap_endianness_vertex_read(edges_idx_degree_data);
				vertex_variable.data       <= swap_endianness_vertex_read(vertex_read_data);
			end else begin
				vertex_variable <= 0;
			end
		end
	end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			push_shift            <= 0;
			out_degree_data       <= 0;
			edges_idx_degree_data <= 0;
			vertex_read_data      <= 0;
		end else begin
			if(~switch_shift_hf && start_shift_hf_0) begin
				push_shift            <= 1;
				out_degree_data       <= reg_OUT_DEGREE_0[0:VERTEX_SIZE_BITS-1];
				edges_idx_degree_data <= reg_EDGES_IDX_0[0:VERTEX_SIZE_BITS-1];
				vertex_read_data      <= reg_READ_DATA_0[0:DATA_SIZE_READ_BITS-1];
			end else if(switch_shift_hf && start_shift_hf_1) begin
				push_shift            <= 1;
				out_degree_data       <= reg_OUT_DEGREE_1[0:VERTEX_SIZE_BITS-1];
				edges_idx_degree_data <= reg_EDGES_IDX_1[0:VERTEX_SIZE_BITS-1];
				vertex_read_data      <= reg_READ_DATA_1[0:DATA_SIZE_READ_BITS-1];
			end else begin
				push_shift            <= 0;
				out_degree_data       <= 0;
				edges_idx_degree_data <= 0;
				vertex_read_data      <= 0;
			end
		end
	end


////////////////////////////////////////////////////////////////////////////
//Read Vertex double buffer
////////////////////////////////////////////////////////////////////////////
	assign vertex_buffer_burst_pop = ~vertex_buffer_status.alfull && ~vertex_buffer_burst_status.empty;

	fifo #(
		.WIDTH($bits(VertexInterface)),
		.DEPTH(CACHELINE_VERTEX_NUM  )
	) vertex_job_buffer_burst_fifo_instant (
		.clock   (clock                            ),
		.rstn    (rstn                             ),
		
		.push    (vertex_variable.valid            ),
		.data_in (vertex_variable                  ),
		.full    (vertex_buffer_burst_status.full  ),
		.alFull  (vertex_buffer_burst_status.alfull),
		
		.pop     (vertex_buffer_burst_pop          ),
		.valid   (vertex_buffer_burst_status.valid ),
		.data_out(vertex_burst_variable            ),
		.empty   (vertex_buffer_burst_status.empty )
	);

	fifo #(
		.WIDTH($bits(VertexInterface)   ),
		.DEPTH(CU_VERTEX_JOB_BUFFER_SIZE)
	) vertex_job_buffer_fifo_instant (
		.clock   (clock                      ),
		.rstn    (rstn                       ),
		
		.push    (vertex_burst_variable.valid),
		.data_in (vertex_burst_variable      ),
		.full    (vertex_buffer_status.full  ),
		.alFull  (vertex_buffer_status.alfull),
		
		.pop     (vertex_request_latched     ),
		.valid   (vertex_buffer_status.valid ),
		.data_out(vertex_latched             ),
		.empty   (vertex_buffer_status.empty )
	);

///////////////////////////////////////////////////////////////////////////
//Read Command Vertex double buffer
////////////////////////////////////////////////////////////////////////////

	// always_ff @(posedge clock or negedge rstn) begin
	// 	if(~rstn) begin
	// 		read_command_bus_grant_latched <= 0;
	// 		read_command_bus_request       <= 0;
	// 	end else begin
	// 		if(enabled_cmd) begin
	// 			read_command_bus_grant_latched <= read_command_bus_grant;
	// 			read_command_bus_request       <= read_command_bus_request_latched;
	// 		end
	// 	end
	// end

	always_ff @(posedge clock or negedge rstn) begin
		if(~rstn) begin
			read_command_bus_grant_latched      <= 0;
			read_command_bus_request            <= 0;
			read_command_bus_grant_latched_S2   <= 0;
			read_command_bus_request_latched_S2 <= 0;
		end else begin
			if(enabled_cmd) begin
				read_command_bus_grant_latched      <= read_command_bus_grant_latched_S2;
				read_command_bus_request            <= read_command_bus_request_latched_S2;
				read_command_bus_grant_latched_S2   <= read_command_bus_grant;
				read_command_bus_request_latched_S2 <= read_command_bus_request_latched;
			end
		end
	end

	assign read_command_bus_request_latched = ~read_buffer_status.alfull && ~read_buffer_status_internal.empty;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(16                      )
	) read_command_job_vertex_burst_fifo_instant (
		.clock   (clock                               ),
		.rstn    (rstn                                ),
		
		.push    (read_command_out_latched_issue.valid),
		.data_in (read_command_out_latched_issue      ),
		.full    (read_buffer_status_internal.full    ),
		.alFull  (read_buffer_status_internal.alfull  ),
		
		.pop     (read_command_bus_grant_latched      ),
		.valid   (read_buffer_status_internal.valid   ),
		.data_out(read_command_out_latched            ),
		.empty   (read_buffer_status_internal.empty   )
	);

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
				read_command_out_latched_NLOCK.size    <= read_response_in_latched.cmd.size;
				read_command_out_latched_NLOCK.address <= read_response_in_latched.cmd.address_offset;
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
			if(read_command_edge_data_burst_out_latched_NLOCK.valid && ~read_command_vertex_job_latched.valid)
				read_command_out_latched_issue <= read_command_edge_data_burst_out_latched_NLOCK;
			else
				read_command_out_latched_issue <= read_command_vertex_job_latched;
		end
	end
	assign read_command_bus_grant_latched_NLOCK = ~read_buffer_status_internal.alfull && ~read_buffer_status_internal_NLOCK.empty && ~read_command_vertex_job_latched.valid;

	fifo #(
		.WIDTH($bits(CommandBufferLine)),
		.DEPTH(16                      )
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