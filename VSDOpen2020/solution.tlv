\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/c1719d5b338896577b79ee76c2f443ca2a76e14f/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)

\TLV cpu_viz(@_stage)
   // String representations of the instructions for debug.
   \SV_plus
      logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
      assign instr_strs = '{m4_asm_mem_expr "END                                     "};
   |cpu
      @1
         /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
            $instr_str[40*8-1:0] = *instr_strs[imem];
            \viz_alpha
               renderEach: function() {
                  // Instruction memory is constant, so just create it once.
                  if (!global.instr_mem_drawn) {
                     global.instr_mem_drawn = [];
                  }
                  if (!global.instr_mem_drawn[this.getIndex()]) {
                     global.instr_mem_drawn[this.getIndex()] = true;
                     let instr_str = '$instr_str'.asString() + ": " + '$instr'.asBinaryStr(NaN);
                     this.getCanvas().add(new fabric.Text(instr_str, {
                        top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                        left: -580,
                        fontSize: 14,
                        fontFamily: "monospace"
                     }));
                  }
               }


      @1
         // m4_mnemonic_expr is build for WARP-V signal names, which are slightly different. Correct them.
         m4_define(['m4_modified_mnemonic_expr'], ['m4_patsubst(m4_mnemonic_expr, ['_instr'], [''])'])
         $mnemonic[10*8-1:0] = $is_blt  ? "BLT       " :
                               $is_addi ? "ADDI      " :
                               $is_add  ? "ADD       " :  "UNKNOWN   ";
         $valid = ! $reset;
         \viz_alpha
            //
            renderEach: function() {
               debugger;
               //
               // PC instr_mem pointer
               //
               let $pc = '$pc';
               let color = !('$valid'.asBool()) ? "gray" :
                                                  "blue";
               let pcPointer = new fabric.Text("->", {
                  top: 18 * ($pc.asInt() / 4),
                  left: -600,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               //
               //
               // Fetch Instruction
               //
               // TODO: indexing only works in direct lineage.  let fetchInstr = new fabric.Text('|fetch/instr_mem[$Pc]$instr'.asString(), {  // TODO: make indexing recursive.
               //let fetchInstr = new fabric.Text('$raw'.asString("--"), {
               //   top: 50,
               //   left: 90,
               //   fill: color,
               //   fontSize: 14,
               //   fontFamily: "monospace"
               //});
               //
               // Instruction with values.
               //
               let regStr = (valid, regNum, regValue) => {
                  return valid ? `r${regNum} (${regValue})` : `rX`;
               };
               let srcStr = ($src, $valid, $reg, $value) => {
                  return $valid.asBool(false)
                             ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                             : "";
               };
               let str = `${regStr('$rd_valid'.asBool(false), '$rd'.asInt(NaN), '$result'.asInt(NaN))}\n` +
                         `  = ${'$mnemonic'.asString()}${srcStr(1, '$rs1_valid', '$rs1', '$src1_value')}${srcStr(2, '$rs2_valid', '$rs2', '$src2_value')}\n` +
                         `      i[${'$imm'.asInt(NaN)}]`;
               let instrWithValues = new fabric.Text(str, {
                  top: 70,
                  left: 90,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               return {objects: [pcPointer, instrWithValues]};
            }
         //
         // Register file
         //
         /xreg[31:0]           
            \viz_alpha
               initEach: function() {
                  let regname = new fabric.Text("Reg File", {
                        top: -20,
                        left: 367,
                        fontSize: 14,
                        fontFamily: "monospace"
                     });
                  let reg = new fabric.Text("", {
                     top: 18 * this.getIndex(),
                     left: 375,
                     fontSize: 14,
                     fontFamily: "monospace"
                  });
                  return {objects: {regname: regname, reg: reg}};
               },
               renderEach: function() {
                  let mod = '$wr'.asBool(false);
                  let reg = parseInt(this.getIndex());
                  let regIdent = reg.toString();
                  let oldValStr = mod ? `(${'>>1$value'.asInt(NaN).toString()})` : "";
                  this.getInitObject("reg").setText(
                     regIdent + ": " +
                     '$value'.asInt(NaN).toString() + oldValStr);
                  this.getInitObject("reg").setFill(mod ? "blue" : "black");
               }
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
      @1
         $reset = *reset;
         
         
         $pc[31:0]   =  >>1$reset        ? '0 :
                        >>1$taken_branch ? >>1$br_target_pc :
                                           >>1$pc + 32'd4;
      
         $imem_rd_en                          = !$reset;
         $imem_rd_addr[3-1:0] = $pc[3+1:2];
         $instr[31:0]                         = $imem_rd_data[31:0];
      
      // Lab for slide 10: Instruction Types Decode and Immediate Decode
      @1
         // Types
         $is_i_instr = $instr[6:2] ==? 5'b0000x ||
                       $instr[6:2] ==? 5'b001x0 ||
                       $instr[6:2] ==? 5'b11001 ;
         
         $is_r_instr = $instr[6:2] ==? 5'b01011 ||
                       $instr[6:2] ==? 5'b011x0 ||
                       $instr[6:2] ==? 5'b10100 ;
         
         $is_b_instr = $instr[6:2] ==? 5'b11000;
         

         // Immediate
         $imm[31:0]  =  $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                        $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
                                       32'b0 ;
      
         
      // Other fields
         $funct7[6:0] = $instr[31:25];
         $funct3[2:0] = $instr[14:12];
         $rs1[4:0]    = $instr[19:15];
         $rs2[4:0]    = $instr[24:20];
         $rd[4:0]     = $instr[11:7];
         $opcode[6:0] = $instr[6:0];
      
      
         $dec_bits[10:0] = {$funct7[5], $funct3, $opcode};
         $is_blt     =  $dec_bits ==? 11'bx_100_1100011;
         
         $is_addi    =  $dec_bits ==? 11'bx_000_0010011;
         $is_add     =  $dec_bits ==? 11'b0_000_0110011 ;
      

      // Lab for slide 12: RISC-V Instruction Field Decode
      
      @1
         $rs1_valid    = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs2_valid    = $is_r_instr || $is_s_instr || $is_b_instr ;
         $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
      
      
         $rf_rd_en1           =  $rs1_valid;
         $rf_rd_en2           =  $rs2_valid;
         $rf_rd_index1[4:0]   =  $rs1;
         $rf_rd_index2[4:0]   =  $rs2;
      
         $src1_value[31:0]    =  $rf_rd_data1;
         $src2_value[31:0]    =  $rf_rd_data2;
      
      
         $rf_wr_en            =  $rd_valid && $rd != 5'b0;
         $rf_wr_index[4:0]    =  $rd;
         $rf_wr_data[31:0]    =  $result;
      
         $result[31:0] =   $is_addi ?  $src1_value + $imm :
                           $is_add  ?  $src1_value + $src2_value :
                                       32'bx;
      
      
         $taken_branch = $is_blt  ? (($src1_value < $src2_value)  ^ ($src1_value[31] != $src2_value[31])) :
                                    1'b0;
      
      
         $br_target_pc[31:0] = $pc + $imm;
      
      
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = |cpu/xreg[10]>>1$value == (1+2+3+4+5+6+7+8+9);
   *failed = *cyc_cnt > 50;
   
   |cpu
      m4+imem(@1)    // Args: (read stage)
      m4+rf(@1, @1)  // Args: (read stage, write stage) - if equal, no register bypass is required
   
   m4+cpu_viz(@1)    // For visualisation, argument should be at least equal to the last stage of CPU logic
                       // @4 would work for all labs

   // ============================================================================================================

   // The stage that is represented by visualization.
   


\SV
   endmodule
