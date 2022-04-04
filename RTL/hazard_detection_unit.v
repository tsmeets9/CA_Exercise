module hazard_detection_unit(
      input  wire [4:0] Rs1,
      input  wire [4:0] Rs2,
      input  wire [4:0] Rd_ID_EX,
      input  wire             MemRead_ID_EX,
      output reg              Stall, 
      output reg              PCWrite,
      output reg              Write_IF_ID

   );

always@(*)begin
      if (MemRead_ID_EX & ((Rd_ID_EX == Rs1) | (Rd_ID_EX == Rs2))) begin 
            // Stall pipeline
            Stall = 1'b1;
            PCWrite = 1'b1;
            Write_IF_ID = 1'b1;
      end
      else begin
            // Do the opposite 
            Stall = 1'b0;
            PCWrite = 1'b0;
            Write_IF_ID = 1'b0;
      end
end
endmodule

