
import CAPI_PKG::*;

module error_control (
  input logic clock,    // Clock
  input logic rstn,
  input logic enabled,
  input logic [0:63] external_errors,
  input logic report_errors_ack,
  output logic reset_error,
  output logic [0:63]  report_errors
);

typedef enum int unsigned {
  ERROR_RESET,
  ERROR_IDLE,
  ERROR_MMIO_REQ,
  ERROR_WAIT_MMIO_REQ,
  ERROR_RESET_REQ,
  ERROR_REPORT,
  ERROR_FLAG_CLR
} error_state;

error_state current_state, next_state;
logic error_flag;
logic error_flag_latched;

assign error_flag = |external_errors;

always_ff @(posedge clock or negedge rstn) begin
	if(~rstn)
		if(error_flag_latched)
			current_state <= ERROR_REPORT;
		else
			current_state <= ERROR_RESET;
	else
		current_state <= next_state;
end // always_ff @(posedge clock)

always_comb begin
	next_state = ERROR_IDLE;
	case (current_state)
		ERROR_RESET: begin
			next_state = ERROR_IDLE;
		end 
		ERROR_IDLE: begin
			if(error_flag)
				next_state = ERROR_MMIO_REQ;
			else
				next_state = ERROR_IDLE;
		end 
		ERROR_MMIO_REQ: begin
			if(report_errors_ack)
				next_state = ERROR_RESET_REQ;
			else
				next_state = ERROR_MMIO_REQ;
		end 		
		ERROR_RESET_REQ: begin
			next_state = ERROR_REPORT;			
		end 
		ERROR_REPORT: begin
			next_state = ERROR_FLAG_CLR;
		end
		ERROR_FLAG_CLR: begin
			next_state = ERROR_IDLE;
		end 
	endcase
end 

always_ff @(posedge clock) begin
	case (current_state)
        ERROR_RESET: begin
        	report_errors 		  <= 64'b0;
        	reset_error	  		  <= 1'b1;
        	error_flag_latched	  <= 1'b0;
		end 
		ERROR_IDLE: begin
			report_errors 	   <= external_errors;
        	reset_error	  	   <= 1'b1;
        	error_flag_latched <= error_flag;
		end 
		ERROR_MMIO_REQ: begin
			
		end 		
		ERROR_RESET_REQ: begin
			reset_error	  <= 1'b0;
		end
		ERROR_REPORT: begin
			reset_error	  <= 1'b1;
		end
		ERROR_FLAG_CLR: begin
			error_flag_latched	  <= 1'b0;
		end 
	endcase
end


endmodule