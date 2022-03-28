//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory

// IMPORTANT NOTES: regdst of control unit is not in use.

module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;
wire [      31:0] instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2;

wire signed [63:0] immediate_extended;
wire [4:0] instruction_11_7_EX_MEM;
wire [4:0] instruction_11_7_MEM_WB;
wire reg_write_EX_MEM;
wire reg_write_MEM_WB;
wire [63:0] branch_pc_EX_MEM;
wire [63:0] jump_pc_EX_MEM;
wire [63:0] alu_out_EX_MEM;




//// IF STAGE BEGIN
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc_EX_MEM ),
   .jump_pc   (jump_pc_EX_MEM   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

// The instruction memory.
sram_BW32 #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

//// IF STAGE END

//// IF_ID REG BEGIN

// IF_ID Pipeline register for instruction signal
wire [31:0] instruction_IF_ID;
reg_arstn_en#(
   .DATA_W(32) // width of the forwarded signal
)signal_pipe_instruction_IF_ID(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction   ),
   .en      (enable        ),
   .dout   (instruction_IF_ID)
);

// IF_ID Pipeline register for updated_pc
wire [63:0] updated_pc_IF_ID;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_updated_pc_IF_ID(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (updated_pc   ),
   .en      (enable        ),
   .dout   (updated_pc_IF_ID)
);
// IF_ID REG END
// ID STAGE BEGIN

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write_MEM_WB         ),
   .raddr_1  (instruction_IF_ID[19:15]),
   .raddr_2  (instruction_IF_ID[24:20]),
   .waddr    (instruction_11_7_MEM_WB),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_rdata_1   ),
   .rdata_2  (regfile_rdata_2   )
);

control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);

// ID STAGE END

// ID_EX REG BEGIN

// ID_EX Pipeline register for updated_pc
wire [63:0] updated_pc_ID_EX;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_updated_pc_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (updated_pc_IF_ID   ),
   .en      (enable        ),
   .dout   (updated_pc_ID_EX)
);

// ID_EX Pipeline register for instruction_24_20
wire [4:0] instruction_24_20_ID_EX;
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)signal_pipe_instruction_24_20_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_IF_ID[24:20]   ),
   .en      (enable        ),
   .dout   (instruction_24_20_ID_EX)
);

// ID_EX Pipeline register for instruction_19_15
wire [4:0] instruction_19_15_ID_EX;
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)signal_pipe_instruction_19_15_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_IF_ID[19:15]   ),
   .en      (enable        ),
   .dout   (instruction_19_15_ID_EX)
);

// ID_EX Pipeline register for instruction_11_7
wire [4:0] instruction_11_7_ID_EX;
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)signal_pipe_instruction_11_7_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_IF_ID[11:7]   ),
   .en      (enable        ),
   .dout   (instruction_11_7_ID_EX)
);
// ID_EX Pipeline register for instruction_14_12
wire [2:0] instruction_14_12_ID_EX;
reg_arstn_en#(
   .DATA_W(3) // width of the forwarded signal
)signal_pipe_instruction_14_12_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_IF_ID[14:12]   ),
   .en      (enable        ),
   .dout   (instruction_14_12_ID_EX)
);
// ID_EX Pipeline register for instruction_30
wire instruction_30_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_instruction_30_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_IF_ID[30]   ),
   .en      (enable        ),
   .dout   (instruction_30_ID_EX)
);

// ID_EX Pipeline register for instruction_25
wire instruction_25_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_instruction_25_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_IF_ID[25]   ),
   .en      (enable        ),
   .dout   (instruction_25_ID_EX)
);

// ID_EX Pipeline register for immediate_extended
wire [63:0] immediate_extended_ID_EX;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_immediate_extended_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (immediate_extended),
   .en      (enable        ),
   .dout   (immediate_extended_ID_EX)
);

// ID_EX Pipeline register for regfile_rdata_1
wire [63:0] regfile_rdata_1_ID_EX;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_regfile_rdata_1_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (regfile_rdata_1),
   .en      (enable        ),
   .dout   (regfile_rdata_1_ID_EX)
);

// ID_EX Pipeline register for regfile_rdata_2
wire [63:0] regfile_rdata_2_ID_EX;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_regfile_rdata_2_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (regfile_rdata_2),
   .en      (enable        ),
   .dout   (regfile_rdata_2_ID_EX)
);

// ID_EX Pipeline register for jump
wire jump_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_jump_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (jump),
   .en      (enable        ),
   .dout   (jump_ID_EX)
);

// ID_EX Pipeline register for reg_write
wire reg_write_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_reg_write_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (reg_write),
   .en      (enable        ),
   .dout   (reg_write_ID_EX)
);

// ID_EX Pipeline register for alu_src
wire alu_src_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_alu_src_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (alu_src),
   .en      (enable        ),
   .dout   (alu_src_ID_EX)
);

// ID_EX Pipeline register for mem_write
wire mem_write_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_write_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_write),
   .en      (enable        ),
   .dout   (mem_write_ID_EX)
);

// ID_EX Pipeline register for mem_2_reg
wire mem_2_reg_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_2_reg_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_2_reg),
   .en      (enable        ),
   .dout   (mem_2_reg_ID_EX)
);

// ID_EX Pipeline register for mem_read
wire mem_read_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_read_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_read),
   .en      (enable        ),
   .dout   (mem_read_ID_EX)
);
// ID_EX Pipeline register for branch
wire branch_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_branch_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (branch),
   .en      (enable        ),
   .dout   (branch_ID_EX)
);

// ID_EX Pipeline register for reg_dst
wire reg_dst_ID_EX;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_reg_dst_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (reg_dst),
   .en      (enable        ),
   .dout   (reg_dst_ID_EX)
);

// ID_EX Pipeline register for alu_op
wire [1:0] alu_op_ID_EX;
reg_arstn_en#(
   .DATA_W(2) // width of the forwarded signal
)signal_pipe_alu_op_ID_EX(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (alu_op),
   .en      (enable        ),
   .dout   (alu_op_ID_EX)
);
//// ID_EX_REG END
//// EX STAGE BEGIN

wire [1:0] Forward_1;
wire [1:0] Forward2;
wire [63:0] mux_1_out;
wire [63:0] mux_2_out;

forward_unit forward_unit(
   .Rs1 (instruction_19_15_ID_EX),
   .Rs2 (instruction_24_20_ID_EX   ),
   .Rd_EX_MEM (instruction_11_7_EX_MEM     ),
   .Rd_MEM_WB  (instruction_11_7_MEM_WB         ),
   .RegWrite_EX_MEM(reg_write_EX_MEM       ),
   .RegWrite_MEM_WB  (reg_write_MEM_WB         ),
   .Forward1(Forward_1       ),
   .Forward2 (Forward_2      )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EX),
   .input_b (regfile_rdata_2_ID_EX),
   .select_a(alu_src_ID_EX           ),
   .mux_out (alu_operand_2     )
);

mux_3 #(
   .DATA_W(64)
) alu_operand_1_mux (
   .input_a (regfile_rdata_1_ID_EX),
   .input_b (alu_out_EX_MEM),
   .input_c (regfile_wdata),
   .select_a(Forward_1),
   .mux_out (mux_1_out)
);

mux_3 #(
   .DATA_W(64)
) alu_operand_2_mux (
   .input_a (alu_operand_2),
   .input_b (alu_out_EX_MEM),
   .input_c (regfile_wdata),
   .select_a(Forward_2           ),
   .mux_out (mux_2_out     )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (mux_1_out),
   .alu_in_1 (mux_2_out   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);

alu_control alu_ctrl(
   .func7_5       (instruction_30_ID_EX   ),
   .func7_0       (instruction_25_ID_EX   ),
   .func3         (instruction_14_12_ID_EX),
   .alu_op        (alu_op_ID_EX            ),
   .alu_control   (alu_control       )
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (updated_pc_ID_EX        ),
   .immediate_extended (immediate_extended_ID_EX),
   .branch_pc          (branch_pc         ),
   .jump_pc            (jump_pc           )
);

//// EX STAGE END

//// EX_MEM_REG BEGIN

// EX_MEM Pipeline register for instruction_11_7
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)signal_pipe_instruction_11_7_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_11_7_ID_EX),
   .en      (enable        ),
   .dout   (instruction_11_7_EX_MEM)
);

// EX_MEM Pipeline register for regfile_rdata_2
wire [63:0] regfile_rdata_2_EX_MEM;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_regfile_rdata_2_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (regfile_rdata_2_ID_EX),
   .en      (enable        ),
   .dout   (regfile_rdata_2_EX_MEM)
);

// EX_MEM Pipeline register for alu_out
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_regfile_alu_out_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (alu_out),
   .en      (enable        ),
   .dout   (alu_out_EX_MEM)
);

// EX_MEM Pipeline register for branch_pc
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_branch_pc_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (branch_pc),
   .en      (enable        ),
   .dout   (branch_pc_EX_MEM)
);

// EX_MEM Pipeline register for jump_pc
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_jump_pc_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (jump_pc),
   .en      (enable        ),
   .dout   (jump_pc_EX_MEM)
);

// EX_MEM Pipeline register for zero_flag
wire zero_flag_EX_MEM;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_zero_flag_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (zero_flag),
   .en      (enable        ),
   .dout   (zero_flag_EX_MEM)
);

// EX_MEM Pipeline register for jump
wire jump_EX_MEM;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_jump_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (jump_ID_EX),
   .en      (enable        ),
   .dout   (jump_EX_MEM)
);

// EX_MEM Pipeline register for reg_write
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_reg_write_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (reg_write_ID_EX),
   .en      (enable        ),
   .dout   (reg_write_EX_MEM)
);

// EX_MEM Pipeline register for mem_write
wire mem_write_EX_MEM;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_write_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_write_ID_EX),
   .en      (enable        ),
   .dout   (mem_write_EX_MEM)
);

// EX_MEM Pipeline register for mem_2_reg
wire mem_2_reg_EX_MEM;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_2_reg_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_2_reg_ID_EX),
   .en      (enable        ),
   .dout   (mem_2_reg_EX_MEM)
);

// EX_MEM Pipeline register for mem_read
wire mem_read_EX_MEM;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_read_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_read_ID_EX),
   .en      (enable        ),
   .dout   (mem_read_EX_MEM)
);
// EX_MEM Pipeline register for branch
wire branch_EX_MEM;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_branch_EX_MEM(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (branch_ID_EX),
   .en      (enable        ),
   .dout   (branch_EX_MEM)
);

//// EX_MEM_REG END

//// MEM STAGE BEGIN

// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_EX_MEM        ),
   .wen      (mem_write_EX_MEM      ),
   .ren      (mem_read_EX_MEM       ),
   .wdata    (regfile_rdata_2_EX_MEM),
   .rdata    (mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

//// MEM STAGE END
//// MEM_WB_REG START

// MEM_WB Pipeline register for instruction_11_7
reg_arstn_en#(
   .DATA_W(5) // width of the forwarded signal
)signal_pipe_instruction_11_7_MEM_WB(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (instruction_11_7_EX_MEM),
   .en      (enable        ),
   .dout   (instruction_11_7_MEM_WB)
);

// MEM_WB Pipeline register for mem_data
wire [63:0] mem_data_MEM_WB;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_mem_data_MEM_WB(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_data),
   .en      (enable        ),
   .dout   (mem_data_MEM_WB)
);

// MEM_WB Pipeline register for alu_out
wire [63:0] alu_out_MEM_WB;
reg_arstn_en#(
   .DATA_W(64) // width of the forwarded signal
)signal_pipe_alu_out_MEM_WB(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (alu_out_EX_MEM),
   .en      (enable        ),
   .dout   (alu_out_MEM_WB)
);

// MEM_WB Pipeline register for mem_2_reg
wire mem_2_reg_MEM_WB;
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_mem_2_reg_MEM_WB(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (mem_2_reg_EX_MEM),
   .en      (enable        ),
   .dout   (mem_2_reg_MEM_WB)
);

// MEM_WB Pipeline register for reg_write
reg_arstn_en#(
   .DATA_W(1) // width of the forwarded signal
)signal_pipe_reg_write_MEM_WB(
   .clk     (clk           ),
   .arst_n  (arst_n        ),
   .din     (reg_write_EX_MEM),
   .en      (enable        ),
   .dout   (reg_write_MEM_WB)
);
//// MEM_WB_REG END
//// WB STAGE BEGIN
mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_MEM_WB     ),
   .input_b  (alu_out_MEM_WB      ),
   .select_a (mem_2_reg_MEM_WB    ),
   .mux_out  ( regfile_wdata )
);

//// WB STAGE END

endmodule
