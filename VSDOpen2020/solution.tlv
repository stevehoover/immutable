\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/VSDOpen2020_TLV_RISC-V_Tutorial
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/VSDOpen2020_TLV_RISC-V_Tutorial/e7970e9d04aaa47efca0ba35c14304a48a0cde40/lib/shell.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */

\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   m4_asm(ADD, r10, r0, r0)             // Initialize x10 to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register x14 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register x12.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register x13 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If x13 is less than x12, branch to <loop>
   m4_asm(ADD, r10, r14, r0)            // Store final result to register x10 so that it can be read by main program
   
   
   //m4_define(['TBD'], [''0'])
   //m4_define(['TBDX'], [''])
   m4_define(['TBD'], ['$*'])
   m4_define(['TBDX'], ['$*'])
   
   |view
      @0
         `BOGUS_USE($pc[4:0])
   // Lab: PC
   $pc[31:0] = >>1$reset        ? 32'0 :
               >>1$taken_branch ? >>1$br_target_pc :    // (initially $taken_branch == 0)
                                  TBD(>>1$pc + 32'b100);
   
   
   // Lab: Fetch
   $imem_rd_addr[2:0] = TBD($pc[4:2]);
   $instr[31:0] = TBD($imem_rd_data);
   
   
   // Lab: Instruction Types Decode
   $is_i_instr = $instr[6:5] == 2'b00;
   $is_r_instr = TBD($instr[6:5] == 2'b01 || $instr[6:5] == 2'b10);
   $is_b_instr = TBD($instr[6:5] == 2'b11);
   
   
   // Lab: Instruction Immediate Decode
   $imm[31:0]  = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :   // I-type
                 TBDX($is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :)    // B-type
                 32'b0;   // Default (unused)
   
   
   // Lab: Instruction Field Decode
   $rs2[4:0]    = $instr[24:20];
   $rs1[4:0]    = TBD($instr[19:15]);
   $funct3[2:0] = TBD($instr[14:12]);
   $rd[4:0]     = TBD($instr[11:7]);
   $opcode[6:0] = TBD($instr[6:0]);
   
   
   // Lab: Register Validity Decode
   $rs1_valid = $is_r_instr || $is_i_instr || $is_b_instr;
   $rs2_valid = TBD($is_r_instr || $is_b_instr);
   $rd_valid  = TBD($is_r_instr || $is_i_instr);
   
   
   // Lab: Instruction Decode
   $dec_bits[9:0] = {$funct3, $opcode};
   $is_blt  = $dec_bits == 10'b100_1100011;
   $is_addi = TBD($dec_bits == 10'b000_0010011);
   $is_add  = TBD($dec_bits == 10'b000_0110011);
   
   
   // Lab: Register File Read
   $rf_rd_en1         = TBD($rs1_valid);
   $rf_rd_en2         = TBD($rs2_valid);
   $rf_rd_index1[4:0] = TBD($rs1);
   $rf_rd_index2[4:0] = TBD($rs2);
   
   $src1_value[31:0] = TBD($rf_rd_data1);
   $src2_value[31:0] = TBD($rf_rd_data2);
   
   
   // Lab: ALU
   $result[31:0] = $is_addi ? $src1_value + $imm :    // ADDI: src1 + imm
                   TBDX($is_add  ? $src1_value + $src2_value :)   // ADD: src1 + src2
                              32'b0;   // Default (unused)
   
   
   // Lab: Register File Write
   $rf_wr_en         = TBD($rd_valid /* && $rd != 5'b0 */);
   $rf_wr_index[4:0] = TBD($rd);
   $rf_wr_data[31:0] = TBD($result);
   
   
   // Lab: Branch Condition
   $taken_branch = TBD($is_blt ?  ($src1_value < $src2_value) /* ^ ($src1_value[31] != $src2_value[31]) */  : 1'b0);
   
   
   // Lab: Branch Target
   $br_target_pc[31:0] = TBD($pc + $imm);
   // $taken_branch and $br_target_pc control the PC mux.
   
   
   
   m4+shell()


\SV
   endmodule
