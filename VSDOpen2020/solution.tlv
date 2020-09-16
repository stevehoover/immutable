\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/VSDOpen2020_TLV_RISC-V_Tutorial
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/c1719d5b338896577b79ee76c2f443ca2a76e14f/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */

\TLV shell()
   
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)
   
   // Instruction Memory containing program defined by m4_asm(...) instantiations.
   \SV_plus
      // The program in an instruction memory.
      logic [31:0] instrs [0:8-1];
      assign instrs = '{
         m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])
      };
   /M4_IMEM_HIER
      $instr[31:0] = *instrs\[#imem\];
   $imem_rd_data[31:0] = /imem[$imem_rd_addr]$instr;
   
   // Reg File
   /xreg[31:0]
      $wr = /top$rf_wr_en && (/top$rf_wr_index != 5'b0) && (/top$rf_wr_index == #xreg);
      $value[31:0] = /top$reset ? 32'b0           :
                     $wr        ? /top$rf_wr_data :
                                  $RETAIN;
   $rf_rd_data1[31:0] = /xreg[$rf_rd_index1]>>1$value;
   $rf_rd_data2[31:0] = /xreg[$rf_rd_index2]>>1$value;
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = /xreg[10]>>1$value == (1+2+3+4+5+6+7+8+9);
   *failed = *cyc_cnt > 50;
   
   
   |view
      @0
         // String representations of the instructions for debug.
         \SV_plus
            logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
            assign instr_strs = '{m4_asm_mem_expr "END                                     "};
         $ANY = /top<>0$ANY;
         /M4_IMEM_HIER
            $ANY = /top/imem<>0$ANY;
            $instr_str[40*8-1:0] = *instr_strs[imem];

         $mnemonic[10*8-1:0] = $is_blt  ? "BLT       " :
                               $is_addi ? "ADDI      " :
                               $is_add  ? "ADD       " :  "UNKNOWN   ";
         $valid = ! $reset;
         $fetch_instr_str[40*8-1:0] = *instr_strs\[/top<>0$pc[\$clog2(M4_NUM_INSTRS+1)+1:2]\];
         \viz_alpha
            //
            initEach() {
               let imem_header = new fabric.Text("Instr. Memory", {
                     top: -29,
                     left: -440,
                     fontSize: 18,
                     fontWeight: 800,
                     fontFamily: "monospace"
                  })
               let decode_header = new fabric.Text("Instr. Decode", {
                     top: 0,
                     left: 65,
                     fontSize: 18,
                     fontWeight: 800,
                     fontFamily: "monospace"
                  })
               let rf_header = new fabric.Text("Reg. File", {
                     top: -29 - 40,
                     left: 307,
                     fontSize: 18,
                     fontWeight: 800,
                     fontFamily: "monospace"
                  })
               return {objects: {imem_header, decode_header, rf_header}};
            },
            renderEach: function() {
               //debugger
               //
               // PC instr_mem pointer
               //
               let $pc = '$pc';
               let color = !('$valid'.asBool()) ? "gray" :
                                                  "blue";
               let pcPointer = new fabric.Text("->", {
                  top: 18 * ($pc.asInt() / 4),
                  left: -295,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               })
               let pc_arrow = new fabric.Line([23, 18 * ($pc.asInt() / 4) + 6, 46, 35], {
                  stroke: "#d0e8ff",
                  strokeWidth: 2
               })
               let rs1_arrow = new fabric.Line([330, 18 * '$rf_rd_index1'.asInt() + 6 - 40, 190, 75 + 18 * 2], {
                  stroke: "#d0e8ff",
                  strokeWidth: 2,
                  visible: '$rf_rd_en1'.asBool()
               })
               let rs2_arrow = new fabric.Line([330, 18 * '$rf_rd_index2'.asInt() + 6 - 40, 190, 75 + 18 * 3], {
                  stroke: "#d0e8ff",
                  strokeWidth: 2,
                  visible: '$rf_rd_en2'.asBool()
               })
               let rd_arrow = new fabric.Line([330, 18 * '$rf_wr_index'.asInt() + 6 - 40, 168, 75 + 18 * 0], {
                  stroke: "#d0d0ff",
                  strokeWidth: 3,
                  visible: '$rf_wr_en'.asBool()
               })
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
                  return valid ? `r${regNum}` : `rX`  // valid ? `r${regNum} (${regValue})` : `rX`
               };
               let srcStr = ($src, $valid, $reg, $value) => {
                  return $valid.asBool(false)
                             ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                             : "";
               };
               let str = `${regStr('$rd_valid'.asBool(false), '$rd'.asInt(NaN), '$result'.asInt(NaN))}\n` +
                         `  = ${'$mnemonic'.asString()}${srcStr(1, '$rs1_valid', '$rs1', '$src1_value')}${srcStr(2, '$rs2_valid', '$rs2', '$src2_value')}\n` +
                         ('$is_r_instr'.asBool() ? "" : `      i[${'$imm'.asInt(NaN)}]`);
               let instrWithValues = new fabric.Text(str, {
                  top: 70,
                  left: 65,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               // Animate fetch (and provide onChange behavior for other animation).
               
               let fetch_instr = new fabric.Text('$fetch_instr_str'.asString(), {
                  top: 18 * ($pc.asInt() / 4),
                  left: -272,
                  fill: "blue",
                  fontSize: 14,
                  fontFamily: "monospace"
               })
               fetch_instr.animate({top: 32, left: 50}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
               });
               
               let src1_value = new fabric.Text('$src1_value'.asInt(0).toString(), {
                  left: 316 + 8 * 4,
                  top: 18 * '$rs1'.asInt(0) - 40,
                  fill: "blue",
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: '$rs1_valid'.asBool(false)
               })
               setTimeout(() => {src1_value.animate({left: 166, top: 70 + 18 * 2}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
               })}, 500)
               let src2_value = new fabric.Text('$src2_value'.asInt(0).toString(), {
                  left: 316 + 8 * 4,
                  top: 18 * '$rs2'.asInt(0) - 40,
                  fill: "blue",
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: '$rs2_valid'.asBool(false)
               })
               setTimeout(() => {src2_value.animate({left: 166, top: 70 + 18 * 3}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
               })}, 500)
               let result_shadow = new fabric.Text('$result'.asInt(0).toString(), {
                  left: 146,
                  top: 70,
                  fill: "#d0d0ff",
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: false
               })
               let result = new fabric.Text('$result'.asInt(0).toString(), {
                  left: 146,
                  top: 70,
                  fill: "blue",
                  fontSize: 14,
                  fontFamily: "monospace",
                  fontWeight: 800,
                  visible: false
               })
               if ('$rd_valid'.asBool()) {
                  setTimeout(() => {
                     result.setVisible(true)
                     result_shadow.setVisible(true)
                     result.animate({left: 317 + 8 * 4, top: 18 * '$rd'.asInt(0) - 40}, {
                       onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                       duration: 500
                     })
                  }, 1000)
               }
               
               return {objects: [pcPointer, pc_arrow, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr, src1_value, src2_value, result_shadow, result]};
            }
         //
         // Register file
         //
         /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
            $rd = ! /top<>0$reset && /top<>0$pc[4:2] == #imem;
            \viz_alpha
               initEach() {
                 let str = new fabric.Text("", {
                    top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                    left: -600,
                    fontSize: 14,
                    fontFamily: "monospace"
                 })
                 return {objects: {str: str}}
               },
               renderEach: function() {
                  // Instruction memory is constant, so just create it once.
                  if (!global.instr_mem_drawn) {
                     global.instr_mem_drawn = [];
                  }
                  if (!global.instr_mem_drawn[this.getIndex()]) {
                     global.instr_mem_drawn[this.getIndex()] = true
                     let instr_str = '$instr'.asBinaryStr(NaN).padEnd(39) + '$instr_str'.asString()
                     instr_str = instr_str.slice(0, -5)
                     //debugger
                     this.getInitObject("str").setText(instr_str)
                     this.getCanvas().add(this.getInitObject("str"))
                  }
                  this.getInitObject("str").set({textBackgroundColor: '$rd'.asBool() ? "#b0ffff" : "white"})
               }
         /xreg[31:0]
            $ANY = /top/xreg<>0$ANY;
            $rd = (/top<>0$rf_rd_en1 && /top<>0$rf_rd_index1 == #xreg) ||
                  (/top<>0$rf_rd_en2 && /top<>0$rf_rd_index2 == #xreg);
            \viz_alpha
               initEach: function() {
                  return {}  // {objects: {reg: reg}};
               },
               renderEach: function() {
                  let rd = '$rd'.asBool(false);
                  let mod = '$wr'.asBool(false);
                  let reg = parseInt(this.getIndex());
                  let regIdent = reg.toString().padEnd(2, " ");
                  let newValStr = regIdent + ": " + (mod ? '$value'.asInt(NaN).toString() : "");
                  let reg_str = new fabric.Text(regIdent + ": " + '>>1$value'.asInt(NaN).toString(), {
                     top: 18 * this.getIndex() - 40,
                     left: 316,
                     fontSize: 14,
                     fill: mod ? "blue" : "black",
                     fontWeight: mod ? 800 : 400,
                     fontFamily: "monospace",
                     textBackgroundColor: rd ? "#b0ffff" : null
                  })
                  if (mod) {
                     setTimeout(() => {
                        console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                        reg_str.set({text: newValStr, dirty: true})
                        this.global.canvas.renderAll()
                     }, 1500)
                  }
                  return {objects: [reg_str]}
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
   
   
   //`define TBD '0
   //`define TBDX
   `define TBD(x) x
   `define TBDX(x) x
   
   $reset = *reset;
   
   
   // Lab: PC
   $pc[31:0] = >>1$reset        ? 32'0 :
               >>1$taken_branch ? >>1$br_target_pc :    // (initially $taken_branch == 0)
                                  `TBD(>>1$pc + 32'b100);
   
   
   // Lab: Fetch
   $imem_rd_addr[2:0] = `TBD($pc[4:2]);
   $instr[31:0] = `TBD($imem_rd_data);
   
   
   // Lab: Instruction Types Decode
   $is_i_instr = $instr[6:5] == 2'b00;
   $is_r_instr = `TBD($instr[6:5] == 2'b01 || $instr[6:5] == 2'b10);
   $is_b_instr = `TBD($instr[6:5] == 2'b11);
   
   
   // Lab: Instruction Immediate Decode
   $imm[31:0]  = $is_i_instr ? { {21{$instr[31]}}, $instr[30:20] } :   // I-type
                 `TBDX($is_b_instr ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :)    // B-type
                 32'b0;   // Default (unused)
   
   
   // Lab: Instruction Field Decode
   $rs2[4:0]    = $instr[24:20];
   $rs1[4:0]    = `TBD($instr[19:15]);
   $funct3[2:0] = `TBD($instr[14:12]);
   $rd[4:0]     = `TBD($instr[11:7]);
   $opcode[6:0] = `TBD($instr[6:0]);
   
   
   // Lab: Register Validity Decode
   $rs1_valid = $is_r_instr || $is_i_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_b_instr ;
   $rd_valid  = $is_r_instr || $is_i_instr;
   
   
   // Lab: Instruction Decode
   $dec_bits[9:0] = {$funct3, $opcode};
   $is_blt  = $dec_bits == 10'b100_1100011;
   $is_addi = `TBD($dec_bits == 10'b000_0010011);
   $is_add  = `TBD($dec_bits == 10'b000_0110011);
   
   
   // Lab: Register File Read
   $rf_rd_en1         = `TBD($rs1_valid);
   $rf_rd_en2         = `TBD($rs2_valid);
   $rf_rd_index1[4:0] = `TBD($rs1);
   $rf_rd_index2[4:0] = `TBD($rs2);
   
   $src1_value[31:0] = `TBD($rf_rd_data1);
   $src2_value[31:0] = `TBD($rf_rd_data2);
   
   
   // Lab: ALU
   $result[31:0] = $is_addi ? $src1_value + $imm :    // ADDI: src1 + imm
                   `TBDX($is_add  ? $src1_value + $src2_value :)   // ADD: src1 + src2
                              32'b0;   // Default (unused)
   
   
   // Lab: Register File Write
   $rf_wr_en         = `TBD($rd_valid /* && $rd != 5'b0 */);
   $rf_wr_index[4:0] = `TBD($rd);
   $rf_wr_data[31:0] = `TBD($result);
   
   
   // Lab: Branch Condition
   $taken_branch = `TBD($is_blt ?  ($src1_value < $src2_value) /* ^ ($src1_value[31] != $src2_value[31]) */  : 1'b0);
   
   
   // Lab: Branch Target
   $br_target_pc[31:0] = `TBD($pc + $imm);
   // $taken_branch and $br_target_pc control the PC mux.
   
   
   
   m4+shell()
   
   // ============================================================================================================
   
   // The stage that is represented by visualization.
   


\SV
   endmodule
