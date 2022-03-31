module forward_unit(
      input  wire [4:0] Rs1,
      input  wire [4:0] Rs2,
      input  wire [4:0] Rd_EX_MEM,
      input  wire [4:0] Rd_MEM_WB,
      input  wire              RegWrite_EX_MEM,
      input  wire              RegWrite_MEM_WB,
      output wire [1:0]        Forward1, 
      output wire [1:0]        Forward2
   );
    reg Forward1_EX_MEM;
    reg Forward2_EX_MEM;
    reg Forward1_MEM_WB;
    reg Forward2_MEM_WB;
    
    assign Forward1 = {Forward1_MEM_WB, Forward1_EX_MEM};
    assign Forward2 = {Forward2_MEM_WB, Forward2_EX_MEM};


   always@(*)begin
        case(RegWrite_EX_MEM)
            1'b1 : begin
                if (Rd_EX_MEM == Rs1) begin
                        Forward1_EX_MEM = 1'b1;
                    end else begin 
                        Forward1_EX_MEM = 1'b0;
                    end
                if (Rd_EX_MEM == Rs2) begin
                        Forward2_EX_MEM = 1'b1;
                    end else begin 
                        Forward2_EX_MEM = 1'b0;
                    end   
                end
            1'b0 : begin
                Forward1_EX_MEM = 1'b0;
                Forward2_EX_MEM = 1'b0;
                end
            default : begin
                Forward1_EX_MEM = 1'b0;
                Forward2_EX_MEM = 1'b0;
                end
        endcase

        case(RegWrite_MEM_WB)
            1'b1 : begin
                if (Rd_MEM_WB == Rs1) begin
                        Forward1_MEM_WB = 1'b1;
                    end else begin 
                        Forward1_MEM_WB = 1'b0;
                    end
                if (Rd_MEM_WB == Rs2) begin
                        Forward2_MEM_WB = 1'b1;
                    end else begin 
                        Forward2_MEM_WB = 1'b0;
                    end   
                end
            1'b0 : begin
                Forward1_MEM_WB = 1'b0;
                Forward2_MEM_WB = 1'b0;
                end
            default : begin
                Forward1_MEM_WB = 1'b0;
                Forward2_MEM_WB = 1'b0;
                end
        endcase
   end
endmodule
