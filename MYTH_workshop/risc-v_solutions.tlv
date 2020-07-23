\m4_TLV_version 1d: tl-x.org
\SV
m4+definitions(['
   m4_define(['m4_lab'], ['m4_define(['m4_slide_cnt'], m4_eval(m4_slide_cnt + $1))m4_ifelse_block(m4_eval(m4_slide_cnt <= m4_slide), 1, ['['// Lab for slide ']m4_slide_cnt[': ']$2'])'])
   //// If not m4_pipelined, m4_stage(@#) will evaluate to @1.
   //m4_define(['m4_stage'], ['m4_ifelse(m4_pipelined, 0, @1, $1)'])
   //m4_define(['m4_pipelined'], 0)
      
      

'])
\TLV hidden_solution(_slide_num)
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/shivam/tlv_lib/risc-v_shell_lib.tlv'])

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
   m4_asm(ADD, r10, r0, r0)             // Initialize r10 (a0) to 0.
   // Function:
   m4_asm(ADD, r14, r10, r0)            // Initialize sum register a4 with 0x0
   m4_asm(ADDI, r12, r10, 1010)         // Store count of 10 in register a2.
   m4_asm(ADD, r13, r10, r0)            // Initialize intermediate sum register a3 with 0
   // Loop:
   m4_asm(ADD, r14, r13, r14)           // Incremental addition
   m4_asm(ADDI, r13, r13, 1)            // Increment intermediate register by 1
   m4_asm(BLT, r13, r12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   m4_asm(ADD, r10, r14, r0)            // Store final result to register a0 so that it can be read by main program
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)

   |cpu
      @0
         $reset = *reset;
      
      
      
      
      
      // ============================================================================================================
      // Solutions: Cut this section to provide the shell.
      
      m4_define(['m4_slide'], _slide_num)  // Build core for this slide
      
      m4_define(['m4_slide_cnt'], 0)  // Increments by the given number of slides for each lab.
      // Define the logic that will be included, based on slide number (specified as slide deltas between labs so editing is easier if slides are added).
      m4_lab(6, ['Next PC
      m4_define(['m4_pc_style'], 1)
      '])
      m4_lab(1, ['Fetch
      @1
         $instr[31:0] = /imem[$pc[M4_IMEM_INDEX_CNT+1:2]]$instr;
      '])
      m4_lab(2, ['Instruction Type Decode
      @1
         $is_i_instr = $instr[6:2] ==? 5'b0000x ||
                       $instr[6:2] ==? 5'b001x0 ||
                       $instr[6:2] ==  5'b11001 ;
         
         $is_r_instr = $instr[6:2] ==  5'b01011 ||
                       $instr[6:2] ==? 5'b011x0 ||
                       $instr[6:2] ==  5'b10100 ;
         
         $is_s_instr = $instr[6:2] ==? 5'b0100x;
         
         $is_b_instr = $instr[6:2] ==  5'b11000;
         
         $is_j_instr = $instr[6:2] ==  5'b11011;
         
         $is_u_instr = $instr[6:2] ==? 5'b0x101;
      '])
      m4_lab(1, ['Instruction Immediate Decode
      @1
         $imm[31:0]  =  $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                        $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:7]} :
                        $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
                        $is_u_instr ? {$instr[31:12], 12'b0} :
                        $is_j_instr ? {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                                       32'b0 ;
      '])
      m4_lab(1, ['Instruction Decode
      m4_define(['m4_fields_style'], 1)
      '])
      m4_lab(1, ['RISC-V Instruction Field Decode
      m4_define(['m4_fields_style'], 2)
      @1
         $funct7_valid = $is_r_instr;
         $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs1_valid    = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs2_valid    = $is_r_instr || $is_s_instr || $is_b_instr ;
         $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
      '])
      m4_lab(1, ['Instruction Decode
      @1
         $funct3_opcode[9:0] = {$funct3, $opcode};
         $is_beq  = $funct3_opcode == 10'b000_1100011;
         $is_bne  = $funct3_opcode == 10'b001_1100011;
         $is_blt  = $funct3_opcode == 10'b100_1100011;
         $is_bge  = $funct3_opcode == 10'b101_1100011;
         $is_bltu = $funct3_opcode == 10'b110_1100011;
         $is_bgeu = $funct3_opcode == 10'b111_1100011;
         $is_addi = $funct3_opcode == 10'b000_0010011;
         $is_add  = $funct3_opcode == 10'b000_0110011;
         `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add)
      '])
      m4_lab(2, ['Register File Inputs
      m4_define(['m4_regfileio_style'], 1)
      '])
      m4_lab(1, ['Register File Read
      m4_define(['m4_regfileio_style'], 2)
      '])
      m4_lab(1, ['
      m4_lab(1, ['ALU
      m4_define(['m4_alu_stage'], @1)
      '])
      m4_lab(2, ['Register File Write
      m4_define(['m4_rf_stage'], @1)
      m4_define(['m4_wr_stage'], @1)
      '])
      m4_lab(1, ['Branches 1
      m4_define(['m4_br_stage'], @1)
      '])
      m4_lab(1, ['Branches 2
      m4_define(['m4_pc_style'], 2)
      m4_define(['m4_tgt_stage'], @1)
      '])
      m4_lab(1, ['Testbench
      m4_define(['m4_tb_stage'], @1)
      '])
      
      
   
      // Logic that changes throughout.
      m4_ifelse_block(m4_pc_style, 1, ['
      @0
         // Lab : Next PC (6)
         $pc[31:0]  =   $reset ? 32'b0 : 
                        >>1$pc + 32'd4;
      '], m4_pc_style, 2, ['
      @0
         $pc[31:0] = $reset       ? '0 :
                     >>1$taken_br ? >>1$br_tgt_pc :
                                    >>1$pc + 32'd4;
      m4_tgt_stage
         $br_tgt_pc[31:0] = $pc + $imm;
      '])
      m4_ifelse_block(m4_fields_style, 1, ['
      @1
         $funct7[6:0] = $instr[31:25];
         $funct3[2:0] = $instr[14:12];
         $rs1[4:0]    = $instr[19:15];
         $rs2[4:0]    = $instr[24:20];
         $rd[4:0]     = $instr[11:7];
         $opcode[6:0] = $instr[6:0];
      '], m4_fields_style, 2, ['         // Other fields
      @1
         ?$funct7_valid
            $funct7[6:0] = $instr[31:25];
         ?$funct3_valid
            $funct3[2:0] = $instr[14:12];
         ?$rs1_valid
            $rs1[4:0]    = $instr[19:15];
         ?$rs2_valid
            $rs2[4:0]    = $instr[24:20];
         ?$rd_valid
            $rd[4:0]     = $instr[11:7];
         $opcode[6:0]    = $instr[6:0];
      '])
      m4_ifelse_block(m4_regfileio_style, 1, ['
         // $rf_wr_en            = '0;
         // $rf_wr_index[4:0]    = '0;
         // $rf_wr_data[31:0]    = '0;
         $rf_rd_en1           = '0;
         $rd_rd_en2           = '0;
         $rf_rd_index1[4:0]   = '0;
         $rf_rd_index2[4:0]   = '0;
      '], m4_regfile_io_style, 2, ['
         // $rf_wr_en            = '0;
         // $rf_wr_index[4:0]    = '0;
         // $rf_wr_data[31:0]    = '0;
         $rf_rd_en1           = $rs1_valid;
         $rd_rd_en2           = $rs2_valid;
         $rf_rd_index1[4:0]   = $rs1;
         $rf_rd_index2[4:0]   = $rs2;
         m4+rf(@1, @1)
         $src1_value[31:0]    = $rf_rd_data1;
         $src2_value[31:0]    = $rf_rd_data2;
      '])
      // m4_ifelse_block(m4_rf_stage, [''] , [''], ['
      // m4_rf_stage
      //    ?$rs1_valid
      //       $rs1_value[31:0] =   (>>1$rd == $rs1) && /xreg[>>1$rd]>>1$wr ? >>1$result :
      //                            /xreg[$rs1]>>1$value;
      //    ?$rs2_valid
      //       $rs2_value[31:0] =   (>>1$rd == $rs2) && /xreg[>>1$rd]>>1$wr ? >>1$result :
      //                            /xreg[$rs2]>>1$value;
      // '])
      m4_ifelse_block(m4_alu_stage, [''], [''], ['
      m4_alu_stage
         $result[31:0] =   $is_addi ?  $rs1_value + $imm :
                           $is_add  ?  $rs1_value + $rs2_value :
                                       32'bx;
      '])
      m4_ifelse_block(m4_wr_stage, [''], [''], m4_wr_stage, ['-'], ['
         /xreg[31:0]
            $value[31:0] = #xreg;
      '], ['
      m4_wr_stage
         /xreg[31:0]
            $wr = |cpu$rd_valid && (|cpu$rd != 5'b0) && (#xreg == |cpu$rd);
            $value[31:0] = *reset ? 32'b0 :
                           $wr    ? |cpu$result :
                                    >>1$value;
      '])
      m4_ifelse_block(m4_br_stage, [''], [''], ['
      @1
         $taken_br = ($is_beq && ($rs1_value == $rs2_value)) ||
                     ($is_bne && ($rs1_value != $rs2_value)) ||
                     ($is_blt && (($rs1_value < $rs2_value)  ^ ($rs1_value[31] != $rs2_value[31]))) ||
                     ($is_bge && (($rs1_value >= $rs2_value) ^ ($rs1_value[31] != $rs2_value[31]))) ||
                     ($is_bltu && ($rs1_value < $rs2_value)) ||
                     ($is_bgeu && ($rs1_value >= $rs2_value));
      '])
      m4_ifelse_block(m4_tb_stage, [''], [''], ['
      m4_tb_stage
         *passed = |cpu/xreg[10]>>1$value == (1+2+3+4+5+6+7+8+9);
      '])
   
   // ============================================================================================================
   
   
   
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   m4_ifelse_block(m4_intermediate, 1, ['
   *passed = *cyc_cnt > 40;
   '])
   *failed = 1'b0;
   
   
   m4+myth_shell()
   
   m4+cpu_viz(@4)


\SV_plus
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   m4+main(1000)   // Slide number of model to build.
\SV_plus
   endmodule
