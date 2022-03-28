module forward_unit(
      input  wire [4:0] Rs1,
      input  wire [4:0] Rs2,
      input  wire [4:0] Rd_EX_MEM,
      input  wire [4:0] Rd_MEM_WB,
      input  wire              RegWrite_EX_MEM,
      input  wire              RegWrite_MEM_WB,
      output reg [1:0]        Forward1, 
      output reg [1:0]        Forward2
   );

   always@(*)begin
        case(RegWrite_EX_MEM)
            1'b1 : 
            case(RegWrite_MEM_WB)
                1'b1 : begin
                    if (Rd_EX_MEM == Rs1) begin 
                        if (Rd_MEM_WB == Rs2) begin
                            Forward1 = 2'b01;
                            Forward2 = 2'b10;
                        end else begin
                            Forward1 = 2'b01;
                            Forward2 = 2'b00;
                        end
                    end
                    else if (Rd_EX_MEM == Rs2) begin
                        if (Rd_MEM_WB == Rs1) begin
                            Forward1 = 2'b10;
                            Forward2 = 2'b01;
                        end else begin
                            Forward1 = 2'b00;
                            Forward2 = 2'b01;
                        end
                    end
                    else begin 
                        if (Rd_MEM_WB == Rs1) begin
                            Forward1 = 2'b10;
                            Forward2 = 2'b00;
                        end else if (Rd_MEM_WB == Rs2) begin
                            Forward1 = 2'b00;
                            Forward2 = 2'b10;
                        end else begin
                            Forward1 = 2'b00;
                            Forward2 = 2'b00;
                        end
                    end
                end
                1'b0 : begin
                    if (Rd_EX_MEM == Rs1) begin
                        Forward1 = 2'b01;
                        Forward2 = 2'b00;
                    end else if (Rd_EX_MEM == Rs2) begin
                        Forward1 = 2'b00;
                        Forward2 = 2'b01;
                    end else begin
                        Forward1 = 2'b00;
                        Forward2 = 2'b00;
                    end
                end 
                default : begin 
                    Forward1 = 2'b00;
                    Forward2 = 2'b00;
                end  
            endcase
            1'b0 : 
            case(RegWrite_MEM_WB)
                1'b1 : begin
                    if (Rd_MEM_WB == Rs1) begin
                        Forward1 = 2'b10;
                        Forward2 = 2'b00;
                    end else if (Rd_MEM_WB == Rs2) begin
                        Forward1 = 2'b00;
                        Forward2 = 2'b10;
                    end else begin
                        Forward1 = 2'b00;
                        Forward2 = 2'b00;
                    end
                end
                1'b0 : begin
                    Forward1 = 2'b00;
                    Forward2 = 2'b00;
                end
                default : begin 
                    Forward1 = 2'b00;
                    Forward2 = 2'b00;
                end 
            endcase
            default: begin 
                Forward1 = 2'b00;
                Forward2 = 2'b00;
            end
        endcase 
   end
endmodule
