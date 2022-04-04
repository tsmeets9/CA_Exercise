module branch_taken 
  #(
   parameter integer DATA_W = 16
   )(
      input  wire [DATA_W-1:0] input_a,
      input  wire [DATA_W-1:0] input_b,
      output wire out
   );

assign out = (input_a == input_b);
endmodule
