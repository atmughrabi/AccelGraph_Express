import CAPI_PKG::*;
import AFU_PKG::*;

module read_data_control (
  input logic clock,    // Clock
  input logic rstn,   
  input logic enabled, 
  input BufferInterfaceInput buffer_in,
  input CommandTagLine data_read_tag_id_in,
  output logic [0:1] data_read_error,
  output DataControlInterfaceOut read_data_control_out_0,
  output DataControlInterfaceOut read_data_control_out_1
);

logic odd_parity;
logic tag_parity;
logic tag_parity_link;
logic [0:7] data_write_parity;
logic [0:7] data_write_parity_latched;
logic write_valid_latched;
logic [0:7] data_write_parity_link;
BufferInterfaceInput buffer_in_latched;

logic enable_errors;
logic [0:1] detected_errors;
logic data_parity_error;
logic tag_parity_error;


assign odd_parity = 1'b1; // Odd parity
assign enable_errors    = 1'b1; // enable errors

////////////////////////////////////////////////////////////////////////////
//input latching Logic
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        buffer_in_latched <= 0;
        data_write_parity_latched <= 0;
        write_valid_latched <= 0;
    end else begin
      if(enabled) begin
        buffer_in_latched  <= buffer_in;
        data_write_parity_latched <= buffer_in_latched.write_parity;
        write_valid_latched       <= buffer_in_latched.write_valid;
      end else begin
        buffer_in_latched  <= 0;
        data_write_parity_latched <= 0;
        write_valid_latched <= 0;
      end
    end
end


////////////////////////////////////////////////////////////////////////////
//Read Data Buffer switch Logic LSB
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        read_data_control_out_0 <= 0;
    end else if(enabled && buffer_in_latched.write_valid && ~(|buffer_in_latched.write_address)) begin

    case (data_read_tag_id_in.cmd_type)
      CMD_READ: begin 
        read_data_control_out_0.read_data    <= 1'b1;
        read_data_control_out_0.wed_data     <= 1'b0;
      end
      CMD_WED: begin 
        read_data_control_out_0.read_data    <= 1'b0;
        read_data_control_out_0.wed_data     <= 1'b1;
      end
      default : begin
        read_data_control_out_0.read_data    <= 1'b0;
        read_data_control_out_0.wed_data     <= 1'b0;
      end
    endcase

    read_data_control_out_0.line.cu_id       <= data_read_tag_id_in.cu_id;
    read_data_control_out_0.line.cmd_type    <= data_read_tag_id_in.cmd_type;
    read_data_control_out_0.line.data        <= buffer_in_latched.write_data;

    end else begin
      read_data_control_out_0  <= 0;
    end
  end


////////////////////////////////////////////////////////////////////////////
//Read Data Buffer switch Logic MSB
////////////////////////////////////////////////////////////////////////////

always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        read_data_control_out_1 <= 0;
    end else if(enabled && buffer_in_latched.write_valid && (|buffer_in_latched.write_address)) begin

    case (data_read_tag_id_in.cmd_type)
      CMD_READ: begin 
        read_data_control_out_1.read_data    <= 1'b1;
        read_data_control_out_1.wed_data     <= 1'b0;
      end
      CMD_WED: begin 
        read_data_control_out_1.read_data    <= 1'b0;
        read_data_control_out_1.wed_data     <= 1'b1;
      end
      default : begin
        read_data_control_out_1.read_data    <= 1'b0;
        read_data_control_out_1.wed_data     <= 1'b0;
      end
    endcase

    read_data_control_out_1.line.cu_id       <= data_read_tag_id_in.cu_id;
    read_data_control_out_1.line.cmd_type    <= data_read_tag_id_in.cmd_type;
    read_data_control_out_1.line.data        <= buffer_in_latched.write_data;

    end else begin
      read_data_control_out_1  <= 0;
    end
  end

////////////////////////////////////////////////////////////////////////////
//partity check Logic
////////////////////////////////////////////////////////////////////////////
 always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        tag_parity  <= odd_parity;
    end else if(enabled && buffer_in.write_valid) begin
        tag_parity  <= buffer_in.write_tag_parity;
    end else begin
        tag_parity  <= odd_parity;
    end
  end

 parity #(
    .BITS(8)
  ) write_tag_parity_instant (
    .data(buffer_in_latched.write_tag),
    .odd(odd_parity),
    .par(tag_parity_link)
  );

  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
        data_write_parity  <= 8'hff;
    end else if(enabled && buffer_in.write_valid) begin
        data_write_parity  <= buffer_in.write_parity;
    end else begin
        data_write_parity  <= 8'hff;
    end
  end

 dw_parity #(
    .DOUBLE_WORDS(8)
  ) read_data_parity_instant (
    .data(buffer_in_latched.write_data),
    .odd(odd_parity),
    .par(data_write_parity_link)
  );


////////////////////////////////////////////////////////////////////////////
// Error Logic
////////////////////////////////////////////////////////////////////////////
  always_ff @(posedge clock or negedge rstn) begin
    if(~rstn) begin
      tag_parity_error    <= 1'b0;
      data_parity_error   <= 1'b0;
      detected_errors     <= 2'b00;
    end else begin
      tag_parity_error    <= tag_parity_link ^ tag_parity;
      
      if(write_valid_latched)
        data_parity_error   <= |(data_write_parity_link ^ data_write_parity_latched);
      else
        data_parity_error   <= 1'b0;

      detected_errors     <= {tag_parity_error, data_parity_error};
    end
  end

  always_ff @(posedge clock) begin
    if(enable_errors) begin
      data_read_error  <= detected_errors;
    end else  begin
      data_read_error  <= 2'b00;
    end
  end



endmodule