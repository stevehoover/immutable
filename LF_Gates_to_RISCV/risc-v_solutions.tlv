\m4_TLV_version 1d: tl-x.org
\SV

m4+definitions(['
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])

   m4_define(['m4_lab'], 0)
   m4_define(['m4_define_labs'], ['
      m4_define(['M4_$1_LAB'], m4_lab)
      m4_define(['m4_lab'], m4_eval(m4_lab + 1))
      m4_ifelse(['$1'], [''], [''], ['m4_define_labs(m4_shift($@))'])
   '])
   m4_define_labs(START, PC, IMEM, INSTR_TYPE, FIELDS, IMM, SUBSET_INSTRS, RF_MACRO, RF_READ, SUBSET_ALU, RF_WRITE, TAKEN_BR, BR_REDIR, TB,
                  TEST_PROG, ALL_INSTRS, FULL_ALU, JUMP, LD_ST_ADDR, DMEM, LD_DATA, DONE)
   m4_define(['m4_reached'], ['m4_eval(M4_LAB >= M4_$1_LAB), 1'])
'])

\TLV hidden_solution(_lab)
   /* verilator lint_on WIDTH */
   m4_define(['M4_LAB'], ['M4_']['_lab']['_LAB'])
   
   
   m4_define(['m4_prog_macro'], m4_ifelse(m4_reached(['TEST_PROG']), ['test_prog'], ['sum_prog']))
   m4+m4_prog_macro()
   
   //--------------------------------------
   
   m4_ifelse_block(m4_reached(['PC']), ['
   $reset = *reset;
   $next_pc[31:0] =  $reset    ? '0              :
                     m4_ifelse_block(m4_reached(['BR_REDIR']), ['
                     $taken_br ? $br_tgt_pc   :
                     '])
                     m4_ifelse_block(m4_reached(['JUMP']), ['
                     $is_jal   ? $br_tgt_pc   :
                     $is_jalr  ? $jalr_tgt_pc :
                     '])
                     $pc + 32'd4 ;
   $pc[31:0] = >>1$next_pc;
   '])
   
   m4_ifelse_block(m4_reached(['IMEM']), ['
   `READONLY_MEM($pc, $$instr[31:0])
   '])
   
   m4_ifelse_block(m4_reached(['INSTR_TYPE']), ['
   $is_i_instr = $instr[6:2] ==? 5'b0000x ||
                 $instr[6:2] ==? 5'b001x0 ||
                 $instr[6:2] ==? 5'b11001 ;
   
   $is_r_instr = $instr[6:2] ==? 5'b01011 ||
                 $instr[6:2] ==? 5'b011x0 ||
                 $instr[6:2] ==? 5'b10100 ;
   
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   
   $is_b_instr = $instr[6:2] ==? 5'b11000;
   
   $is_j_instr = $instr[6:2] ==? 5'b11011;
   
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   '])
   
   m4_ifelse_block(m4_reached(['FIELDS']), ['
   $funct7[6:0]   =  $instr[31:25];
   $funct3[2:0]   =  $instr[14:12];
   $rs1[4:0]      =  $instr[19:15];
   $rs2[4:0]      =  $instr[24:20];
   $rd[4:0]       =  $instr[11:7];
   $opcode[6:0]   =  $instr[6:0];
   
   $funct7_valid  =  $is_r_instr;
   $funct3_valid  =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs1_valid     =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid     =  $is_r_instr || $is_s_instr || $is_b_instr ;
   $rd_valid      =  $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $imm_valid     =  $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   `BOGUS_USE($funct7 $funct7_valid $funct3 $funct3_valid $rs1 $rs1_valid $rs2
              $rs2_valid $rd $rd_valid $imm_valid $opcode)
   '])
   
   m4_ifelse_block(m4_reached(['IMM']), ['
   $imm[31:0]  =  $is_i_instr ?  {{21{$instr[31]}}, $instr[30:20]}                                  :
                  $is_s_instr ?  {{21{$instr[31]}}, $instr[30:25], $instr[11:7]}                    :
                  $is_b_instr ?  {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0}   :
                  $is_u_instr ?  {$instr[31:12], 12'b0}                                             :
                  $is_j_instr ?  {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                                 32'b0 ;
   '])
   
   m4_ifelse_block(m4_reached(['SUBSET_INSTRS']), ['
   $dec_bits[10:0]   =  {$instr[30], $funct3, $opcode};
   $is_beq           =  $dec_bits ==? 11'bx_000_1100011;
   $is_bne           =  $dec_bits ==? 11'bx_001_1100011;
   $is_blt           =  $dec_bits ==? 11'bx_100_1100011;
   $is_bge           =  $dec_bits ==? 11'bx_101_1100011;
   $is_bltu          =  $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu          =  $dec_bits ==? 11'bx_111_1100011;
   
   $is_addi          =  $dec_bits ==? 11'bx_000_0010011;
   $is_add           =  $dec_bits ==? 11'b0_000_0110011;
   `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add)
   '])
   
   m4_ifelse_block(m4_reached(['RF_WRITE']), ['
   m4_define(['m4_rf_wr_en'],    ['$rd_valid && ($rd != 5'b0)'])
   m4_define(['m4_rf_wr_index'], ['$rd'])
   m4_define(['m4_rf_wr_data'],  ['$result'])
   '], ['
   m4_define(['m4_rf_wr_en'],    ['$rf_wr_en'])
   m4_define(['m4_rf_wr_index'], ['$rf_wr_index[4:0]'])
   m4_define(['m4_rf_wr_data'],  ['$rf_wr_data[31:0]'])
   '])
   m4_ifelse_block(m4_reached(['FULL_ALU']), ['
   // SLTU and SLTI (set if less than, unsigned) results:
   $sltu_rslt[31:0]  = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   // SRA and SRAI (shift right, arithmetic) results:
   //   64-bit sign-extended src1
   $sext_src1[63:0] = { {32{$src1_value[31]}}, $src1_value };
   //   64-bit sign-extended results, to be truncated
   $sra_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   '])
   m4_ifelse_block(m4_reached(['SUBSET_ALU']), ['
   $result[31:0] =   $is_addi  ?  $src1_value + $imm :
                     $is_add   ?  $src1_value + $src2_value :
                     m4_ifelse_block(m4_reached(['FULL_ALU']), ['
                     $is_andi    ?  $src1_value & $imm :
                     $is_ori     ?  $src1_value | $imm :
                     $is_xori    ?  $src1_value ^ $imm :
                     $is_slli    ?  $src1_value << $imm[5:0]  :
                     $is_srli    ?  $src1_value >> $imm[5:0]  :
                     $is_and     ?  $src1_value & $src2_value :
                     $is_or      ?  $src1_value | $src2_value :
                     $is_xor     ?  $src1_value ^ $src2_value :
                     $is_sub     ?  $src1_value - $src2_value :
                     $is_sll     ?  $src1_value << $src2_value[4:0] :
                     $is_srl     ?  $src1_value >> $src2_value[4:0] :
                     $is_sltu    ?  $sltu_rslt :
                     $is_sltiu   ?  $sltiu_rslt :
                     $is_lui     ?  {$imm[31:12], 12'b0} :
                     $is_auipc   ?  $pc + $imm :
                     $is_jal     ?  $pc + 32'd4 :
                     $is_jalr    ?  $pc + 32'd4 :
                     $is_slt   ?  ( ($src1_value[31] == $src2_value[31]) ?
                                        $sltu_rslt :
                                        {31'b0, $src1_value[31]} )          :
                     $is_slti  ?  ( ($src1_value[31] == $imm[31]) ?
                                        $sltiu_rslt :
                                        {31'b0, $src1_value[31]} )          :
                     $is_sra   ?  $sra_rslt[31:0]                           :
                     $is_srai  ?  $srai_rslt[31:0]                          :
                     '])
                     m4_ifelse_block(m4_reached(['LD_ST_ADDR']), ['
                     $is_load || $is_s_instr ?  $src1_value + $imm :
                     '])
                                  32'b0;
   '])
   
   
   m4_ifelse_block(m4_reached(['TAKEN_BR']), ['
   $taken_br   =  $is_beq  ?  ($src1_value == $src2_value) :
                  $is_bne  ?  ($src1_value != $src2_value) :
                  $is_blt  ?  (($src1_value < $src2_value)  ^ ($src1_value[31] != $src2_value[31])) :
                  $is_bge  ?  (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                  $is_bltu ?  ($src1_value < $src2_value)  :
                  $is_bgeu ?  ($src1_value >= $src2_value) :
                              1'b0;
   '])

   m4_ifelse_block(m4_reached(['BR_REDIR']), ['
   $br_tgt_pc[31:0]  =  $pc + $imm;
   '])
      
   m4_ifelse_block(m4_reached(['ALL_INSTRS']), ['
   $is_lui     =  $dec_bits ==? 11'bx_xxx_0110111 ;
   $is_auipc   =  $dec_bits ==? 11'bx_xxx_0010111 ;
   $is_jal     =  $dec_bits ==? 11'bx_xxx_1101111 ;
   $is_jalr    =  $dec_bits ==? 11'bx_000_1100111 ;
   
   $is_load    =  $opcode   ==  7'b0000011        ;
   
   $is_slti    =  $dec_bits ==? 11'bx_010_0010011 ;
   
   $is_sltiu   =  $dec_bits ==? 11'bx_011_0010011 ;
   $is_xori    =  $dec_bits ==? 11'bx_100_0010011 ;
   $is_ori     =  $dec_bits ==? 11'bx_110_0010011 ;
   $is_andi    =  $dec_bits ==? 11'bx_111_0010011 ;
   $is_slli    =  $dec_bits ==? 11'b0_001_0010011 ;
   $is_srli    =  $dec_bits ==? 11'b0_101_0010011 ;
   $is_srai    =  $dec_bits ==? 11'b1_101_0010011 ;

   $is_sub     =  $dec_bits ==? 11'b1_000_0110011 ;
   $is_sll     =  $dec_bits ==? 11'b0_001_0110011 ;
   $is_slt     =  $dec_bits ==? 11'b0_010_0110011 ;
   $is_sltu    =  $dec_bits ==? 11'b0_011_0110011 ;
   $is_xor     =  $dec_bits ==? 11'b0_100_0110011 ;
   $is_srl     =  $dec_bits ==? 11'b0_101_0110011 ;
   $is_sra     =  $dec_bits ==? 11'b1_101_0110011 ;
   $is_or      =  $dec_bits ==? 11'b0_110_0110011 ;
   $is_and     =  $dec_bits ==? 11'b0_111_0110011 ;
   '])
   
   m4_ifelse_block(m4_reached(['JUMP']), ['
   $jalr_tgt_pc[31:0]   =  $src1_value + $imm;
   '])
   
   m4_ifelse_block(m4_reached(['LD_DATA']), ['
   m4_define(['m4_rf_wr_data'], ['$is_load ? $ld_data : $result'])
   '])
   
   // Assert these to end simulation (before Makerchip cycle limit).
   m4_ifelse_block(m4_reached(['TB']), ['
   m4+tb()
   '], ['
   *passed = 1'b0;
   '])
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   //|cpu
   m4_ifelse_block(m4_reached(['RF_READ']), ['
   m4+rf(32, 32, $reset, m4_rf_wr_en, m4_rf_wr_index, m4_rf_wr_data, $rs1_valid, $rs1, $src1_value[31:0], $rs2_valid, $rs2, $src2_value[31:0])
   '], m4_reached(['RF_MACRO']), ['
   m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   '])
   m4_ifelse_block(m4_reached(['DMEM']), ['
   m4+dmem(32, 32, $reset, $result[6:2], $is_s_instr, $src2_value, $is_load, $ld_data)
   '])
   
   //m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd1_en, $rd1_index[4:0], $rd1_data, $rd2_en, $rd2_index[4:0], $rd2_data)
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   m4+cpu_viz()
\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   m4+hidden_solution(DONE)   // Slide number of model to build.
\SV
   endmodule
