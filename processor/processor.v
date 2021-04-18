/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */

 // yay passing addi lmao
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	 
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

	/* YOUR CODE STARTS HERE */

    // Fetching stage
    wire [31:0] pc, pc_jump, pc_next, prop, gen;
    wire [31:0] pc_in, pc_immed, propi, geni;
    wire is_pc_change, is_branch, is_j;
    wire is_stall; // I know I need this, not sure how to populate though
    // Would need to do a mux if its a jump instruction
    assign is_stall = 1'b0; // we haven't implemented stalling, so we did this for now
    assign is_pc_change = is_branch; // just going to have it for branch for now
    assign pc_in = is_pc_change ? pc_immed : pc_next; // this should work for blt/bne
    // wire result_rdy;
    // assign pc_in = pc_next;
    register ro(~clock, pc_in, 1'b1, pc, reset); // PC
    // assign pc_next = pc + 1;
    add_op a0(pc, 32'b1, 1'b0, prop, gen, pc_next); // PC + 1

    assign address_imem = pc[11:0]; // This was according to Piazza
    // assign pc_next = pc + 1;
    // Grab from Instruction Memory -> qmem
    // Do we need to reset imem and qmem? -> I think so?
    wire [31:0] q_imem0, q_dmem0;
    assign q_imem0 = reset ? 32'd0 : q_imem; 
    assign q_dmem0 = reset ? 32'd0 : q_dmem;

    // Second stage: Decoding
    // Goal: to find out if we need to branch
    // We also determine if we need to read a and b
    // Created FD module
    wire [31:0] fd_ir_in, fd_ir, fd_pc; // wire for IR instruction
    assign fd_ir_in = q_imem0; // Grabbed IR instruction
    // FD Latch time
    fd_latch f0(fd_pc, fd_ir, pc_next, fd_ir_in, ~clock, reset, ~is_stall); // all latch clocks must be ~clk

    // Datahazard latch HERE
    // Check if data hazard will occur (check slides)
    // Write nop into dx_ir
    // Clear datapath signals (what is this?)
    // Disable fd_latch and PC write enable -> stalling this is when we turn it off! (my is_stall variable)
    wire data_hazard;
    // assign data_hazard = (fd_ir[21:17] == dx_ir[26:22]) | (fd_ir[])

    // Decoding instructions
    // Time to figure out if we need to branch
    wire [4:0] fd_opcode;
    assign fd_opcode = fd_ir[31:27];
    wire fd_bne, fd_j, fd_jal, fd_jr, fd_bex, fd_setx, fd_blt;
    // Comparison to figure out which instruction it is, 1 or 0
    assign fd_bne = fd_opcode == 5'b00010; // 00010
    assign fd_j = fd_opcode == 5'b00001; // 00001
    assign fd_jal = fd_opcode == 5'b00011; // 00011
    assign fd_jr = fd_opcode == 5'b00100; // 00100
    assign fd_bex = fd_opcode == 5'b10110; // 10110
    // assign fd_setx = fd_opcode == 5'b10101; // 10101 omg misspelled as sex damn I am tireddd
    assign fd_blt = fd_opcode == 5'b00110; // 00110
    // Do we read RD or RT? -> Determination below
    wire [4:0] fd_rs;
    assign fd_rs = fd_ir[21:17];
    // 5'd30 -> 5'b11110
    assign ctrl_readRegA = fd_bex ? 5'd30 : fd_rs; // bex true: 5'd30, false: read from fd_rs
    wire readRDorRT;
    // we check for sw, bne, jr, or blt
    // we also added lw too -> hopefully it won't break
    // pulling wrong value from register but need to figure out why
    assign readRDorRT = (fd_opcode == 5'b00111) | (fd_opcode == 5'b00010) | (fd_opcode == 5'b00100) | (fd_opcode == 5'b00110) | (fd_opcode == 5'b01000);
    assign ctrl_readRegB = readRDorRT ? fd_ir[26:22] : fd_ir[16:12]; // this should work for jumps
   
    // figure out stalling? -> we currently don't have value for it

    // Third stage: Execution
    // We need to choose where A and B are going
    wire [31:0] dx_ir_in, dx_ir, dx_pc, dx_a, dx_b, aluOut;
    wire [4:0] aluOp, aluOpsub;
    assign dx_ir_in = fd_ir;
    dx_latch dx0(dx_a, dx_b, dx_pc, dx_ir, data_readRegA, data_readRegB, fd_pc, dx_ir_in, ~clock, reset);
    //Sign extension -> D/X stage
    wire [31:0] fd_t, fd_i, fast_pcN, prop1, gen1;
    extend_26_32 e0(fd_ir[26:0], fd_t); // Target extension
    extend_16_32 e1(fd_ir[16:0], fd_i); // Immediate extension
    // Again with assigning opcodes uwu
    // Getting ready for execution
    wire is_blt, is_bne, is_jal, is_sw, is_lw, is_addi, is_ALU, is_jr, is_lnf; // hadn't declared these wires
    assign is_blt = dx_ir[31:27] == 5'b00110; // 00110
    assign is_bne = dx_ir[31:27] == 5'b00010;
    assign is_jal = dx_ir[31:27] == 5'b00011; // 00011
    assign is_sw = dx_ir[31:27] == 5'b00111; // 00111
    assign is_lw = dx_ir[31:27] == 5'b01000; // 01000
    assign is_addi = dx_ir[31:27] == 5'b00101; // 00101
    assign is_ALU = dx_ir[31:27] == 5'b00000; // 00000
    assign is_jr = dx_ir[31:27] == 5'b00100; // 00100
    assign aluOpsub = is_blt ? 5'b00001 : dx_ir[6:2]; 
    assign aluOp = (is_addi | is_sw | is_lw) ? 5'b00000 : aluOpsub;
    assign is_lnf = dx_ir[6:2] == 5'b01000; // new instruction lnf 010000
    // shamft assignment
    wire [4:0] shamft;
    wire[31:0] immediate;
    assign shamft = dx_ir[11:7];
    extend_16_32 SXImm(dx_ir[16:0], immediate);
    // time to use ALU
    // don't we need to do decoding for ALU?
    wire ovf, is_NE, is_LT;
    wire [31:0] which_b;
    // Debug bypassing broke everything TT -> Still broke
    // ALUinA Bypassing
    wire alu_selA0, alu_selA1, alu_selA2;
    // (D/X.IR.RS1 == X/M.IR.RD) → mux select = 0
    // (D/X.IR.RS1 == M/W.IR.RD) → mux select = 1
    // Else → mux select = 2

    // 3 cases we can have
    assign alu_selA0 = dx_ir[21:17] == xm_ir[26:22]; // xm_o
    assign alu_selA1 = dx_ir[21:17] == mw_ir[26:22]; // datawriteReg
    assign alu_selA2 = ~alu_selA0 & ~alu_selA1; // dx_a

    wire [1:0] select_A; 
    assign select_A[0] = alu_selA1;
    assign select_A[1] = alu_selA2;

    wire [31:0] alu_A, xm_o;
    mux32_4 alusel(alu_A, select_A, xm_o, data_writeReg, dx_a, dx_a);
    
    // ALUinB Bypassing
    wire alu_selB0, alu_selB1, alu_selB2;
    // RD or RT : I think it's fixed!
    wire [4:0] alu_byp_b, mw_RDorRT, xm_RDorRT;
    wire is_RDorRT;
    wire is_rd_rt, is_byp;
    // we check for sw, bne, jr, or blt
    assign is_RDorRT = is_sw | is_bne | is_jr | is_blt | is_lw;
    assign alu_byp_b = is_RDorRT ? dx_ir[26:22] : dx_ir[16:12];
    wire [4:0] is_xm_rd;
    assign is_xm_rd = xm_ir[26:22];
    assign xm_RDorRT = is_RDorRT ? is_xm_rd : xm_ir[16:12]; 
    // if we aren't xm_rd, DO NOT bypass
    wire if_xm_rd;
    assign if_xm_rd = is_RDorRT == 1;

    assign alu_selB0 = alu_byp_b == is_xm_rd; // xm_rd -> Not the fix, reverting back // xm_o
    assign alu_selB1 = alu_byp_b == mw_ir[26:22]; // datawriteReg
    assign alu_selB2 = ~alu_selB0 & ~alu_selB1; // dx_b

    wire [1:0] select_B;
    wire [31:0] alu_B;
    assign select_B[0] = alu_selB1;
    assign select_B[1] = alu_selB2;
    mux32_4 aluselb(alu_B, select_B, xm_o, data_writeReg, dx_b, dx_b);

    assign which_b = (is_addi | is_sw | is_lw) ? immediate : alu_B;
    // assign which_b = (is_addi | is_sw | is_lw) ? immediate : dx_b;
    //alu ALU(dx_a, which_b, aluOp, shamft, aluOut, is_NE, is_LT, ovf);
    alu ALU(alu_A, which_b, aluOp, shamft, aluOut, is_NE, is_LT, ovf);
    // Linear Register
    wire [1:0] lnf_out;
    // wire [2:0] wire_lnf_out;
    wire [31:0] extend_lnf;
    linear_register lnf(lnf_out, clock, alu_A[0]); // new instruction implementation
    // assign wire_lnf_out = lnf_out;
    extend_3_32 e32(lnf_out, extend_lnf);

    wire do_blt, do_bne, do_linear;
    assign do_blt = is_NE & is_blt;
    assign do_bne = is_LT & is_bne;
    wire is_branch1, is_branch2;
    assign is_branch1 = do_blt & ~do_bne;
    assign is_branch2 = ~do_blt & do_bne;
    assign is_branch = is_branch1 | is_branch2;
    add_op ap1(dx_pc, immediate, 1'b0, propi, geni, pc_immed); // for blt and bne
    // multdiv
    wire [31:0] p_in;
    wire ctrl_DIV, ctrl_MULT, data_exception, data_resultRDY;
    assign ctrl_MULT = is_ALU & aluOp == 5'b00110;
    assign ctrl_DIV = is_ALU & aluOp == 5'b00111;
    multdiv mltd(alu_A, which_b, ctrl_MULT, ctrl_DIV, clock, p_in, data_exception, data_resultRDY);

    // Not too sure about this stalling right here
    wire [31:0] p;
    wire [4:0] pw_rd;
    wire pw_stall, pw_done;
    pw_latch pw0(p, pw_rd, pw_stall, pw_done, p_in, dx_ir, data_resultRDY, data_exception, ~clock, reset);

    // Fourth stage: Memory
    wire [31:0] xm_im_in, xm_o_in, xm_b, xm_ir;
    assign xm_im_in = (ctrl_MULT | ctrl_DIV) ? 0 : dx_ir;
    // mux to choose aluOut or the linear feedback
    assign xm_o_in = is_lnf ? extend_lnf : aluOut; // I think this would be correct
    wire [4:0] latch_rd, xm_rd, xm_aluOp;
    wire [31:0] xm_o_inn;
    xm_inputs xm(latch_rd, xm_o_inn, xm_im_in, ovf, aluOut, dx_pc); // not sure if I would need to change here, actually don't
    m_latch ml0(xm_o, xm_b, xm_ir, xm_rd, xm_o_in, alu_B, xm_im_in, latch_rd, ~clock, reset); // not write_b, should I try to use instead alu_b? I think this would need to be alu_b
    assign xm_aluOp = xm_ir[6:2];
    assign address_dmem = xm_o;
    // assign data = xm_b;                           
    assign wren = (xm_ir[31:27] == 5'b00111); // this for store word
    // The second red bypass that's not ALU
    wire [4:0] xm_is_byp, mw_is_byp; 
    // rd or rt  
    // we check for sw, bne, jr, or blt
    assign is_rd_rt = (xm_ir[31:27] == 5'b00111) | (xm_ir[31:27] == 5'b00010) | (xm_ir[31:27] == 5'b00100) | (xm_ir[31:27] == 5'b00110) | (xm_ir[31:27] == 5'b01000);
    assign xm_is_byp = is_rd_rt ? xm_ir[26:22] : xm_ir[16:12];
    assign mw_is_byp = is_rd_rt ? mw_ir[26:22] : mw_ir[16:12];
    assign is_byp = xm_is_byp == mw_is_byp;         
    assign data = is_byp ? data_writeReg : xm_b;
 
    // Fifth stage: Writeback
    wire [31:0] mw_d, mw_ir, mw_o;
    wire [4:0] mw_rd, mw_opcode;
    m_latch ml1(mw_o, mw_d, mw_ir, mw_rd, xm_o, q_dmem0, xm_ir, xm_rd, ~clock, reset);
    assign ctrl_writeReg =  pw_done ? pw_rd : mw_rd;
    assign mw_opcode = mw_ir[31:27];
    wire writeback_is_jal, writeback_is_setx, writeback_isALUOp, writeback_islw;
    assign writeback_islw = (mw_opcode == 5'b01000);
    assign writeback_isALUOp = (mw_opcode == 5'b0000);
    assign writeback_is_jal = (mw_opcode == 5'b00011);
    assign writeback_is_setx = (mw_opcode == 5'b10101);
    wire [31:0] data_writeReg_prePW;
    assign data_writeReg_prePW = writeback_islw ? mw_d : mw_o;
    assign data_writeReg = pw_done ? p : data_writeReg_prePW;
    assign ctrl_writeEnable = writeback_islw | writeback_isALUOp | writeback_is_jal | writeback_is_setx | (mw_opcode == 5'b00101);
	/* END CODE */

endmodule
