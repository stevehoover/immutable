\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   //m4_include_url(['https://raw.githubusercontent.com/shivampotdar/LF-Build-a-RISC-V-Workshop/main/tlv_lib/risc-v_shell_lib.tlv'])
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv'])

m4+definitions(['
   m4_define_vector(['M4_WORD'], 32)
   m4_define(['M4_EXT_I'], 1)
   
   m4_define(['M4_NUM_INSTRS'], 0)
   
   m4_echo(m4tlv_riscv_gen__body())
'])
  
\TLV fill_imem()
   // The program in an instruction memory.
   \SV_plus
      logic [31:0] instrs [0:M4_NUM_INSTRS-1];
      `define READONLY_MEM(ADDR, DATA) assign DATA = instrs[ADDR[\$clog2(\$size(instrs)) + 1 : 2]];         // Verilog macro for use by students
      assign instrs = '{
         m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])
      };
   
   // mnemonic from warp-v lib expects all is_* to be defined
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['   
   /defaults
      {$is_lui, $is_auipc, $is_jal, $is_jalr, $is_beq, $is_bne, $is_blt, $is_bge, $is_bltu, $is_bgeu, $is_lb, $is_lh, $is_lw, $is_lbu, $is_lhu, $is_sb, $is_sh, $is_sw} = '0;
      {$is_addi, $is_slti, $is_sltiu, $is_xori, $is_ori, $is_andi, $is_slli, $is_srli, $is_srai, $is_add, $is_sub, $is_sll, $is_slt, $is_sltu, $is_xor} = '0;
      {$is_srl, $is_sra, $is_or, $is_and, $is_csrrw, $is_csrrs, $is_csrrc, $is_csrrwi, $is_csrrsi, $is_csrrci} = '0;
      {$is_load, $is_store} = '0;
      `BOGUS_USE($is_lui $is_auipc $is_jal $is_jalr $is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_lb $is_lh $is_lw $is_lbu $is_lhu $is_sb $is_sh $is_sw)
      `BOGUS_USE($is_addi $is_slti $is_sltiu $is_xori $is_ori $is_andi $is_slli $is_srli $is_srai $is_add $is_sub $is_sll $is_slt $is_sltu $is_xor)
      `BOGUS_USE($is_srl $is_sra $is_or $is_and $is_csrrw $is_csrrs $is_csrrc $is_csrrwi $is_csrrsi $is_csrrci)
   
   $ANY = /defaults<>0$ANY;
   
   m4_define(['m4_modified_mnemonic_expr'], ['m4_patsubst(m4_mnemonic_expr, ['_instr'], [''])'])
   $mnemonic[10*8-1:0] = m4_modified_mnemonic_expr $is_load ? "LOAD      " : $is_store ? "STORE     " : "ILLEGAL   ";
   `BOGUS_USE($mnemonic);
   '])

\TLV rf(_entries, _width, $_reset, _port1_mode, $_port1_en, $_port1_index, $_port1_data, _port2_mode, $_port2_en, $_port2_index, $$_port2_data, _port3_mode, $_port3_en, $_port3_index, $$_port3_data)
   /xreg[_entries-1:0]
      /* m4_argn(4, $@) */
      /* m4_forloop(['m4_regport_loop'], 1, 4, ['m4_argn(m4_eval(1 + m4_regport_loop * 4), $@)'])*/
      //$wr = m4_forloop(['m4_regport_loop'], 1, 4, ['m4_ifelse_block(['['_port']m4_regport_loop['_mode']'], W, ['['$_port']m4_regport_loop['_en'] || '], [''])'])
      $wr                  =  /top$_port1_en && (/top$_port1_index != 5'b0) && (/top$_port1_index == #xreg);
      $value[_width-1:0]   =  /top$_reset    ?  #xreg               :   
                              >>1$wr         ?  >>1/top$_port1_data :   
                                                $RETAIN;   
   
   $$_port2_data[_width-1:0]  =  $_port2_en ? /xreg[/top$_port2_index]$value : 'X;
   $$_port3_data[_width-1:0]  =  $_port3_en ? /xreg[/top$_port3_index]$value : 'X;
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['   
   /cpuviz
      $rf_rd_en1 = /top$_port2_en;
      $rf_rd_en2 = /top$_port3_en;
      $rf_rd_index1[\$clog2(_entries)-1:0] = /top$_port2_index;
      $rf_rd_index2[\$clog2(_entries)-1:0] = /top$_port3_index;
      $rf_wr_index[\$clog2(_entries)-1:0]  = /top$_port1_index;
      $rf_wr_en = /top$_port1_en;
   '])

\TLV dmem(_entries, _width, $_reset, _port1_mode, $_port1_en, $_port1_index, $_port1_data, _port2_mode, $_port2_en, $_port2_index, $$_port2_data)
   /dmem[_entries-1:0]
      //$wr = m4_forloop(['m4_regport_loop'], 1, 4, ['m4_ifelse_block(['['_port']m4_regport_loop['_mode']'], W, ['['$_port']m4_regport_loop['_en'] || '], [''])'])
      $wr                  =  /top$_port1_en && (/top$_port1_index == #dmem);
      $value[_width-1:0]   =  /top$_reset    ?     #dmem               :   
                              >>1$wr         ?     >>1/top$_port1_data :   
                                                   $RETAIN;
   
   $$_port2_data[_width-1:0] = $_port2_en ? /dmem[/top$_port2_index]$value : 'X;
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['   
   /cpuviz
      $dmem_rd_en = /top$_port2_en;
      $dmem_rd_index[\$clog2(_entries)-1:0] = /top$_port2_index;
      $dmem_wr_en = /top$_port1_en;
      $dmem_wr_index[\$clog2(_entries)-1:0] = /top$_port1_index;
   '])   

\TLV cpu_viz()
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['
   // String representations of the instructions for debug.
   \SV_plus
      logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
      assign instr_strs = '{m4_asm_mem_expr "END                                     "};
   
   /cpuviz
      $sticky_zero = 1'b0;
      
      $fetch_instr_str[40*8-1:0] = *instr_strs\[/top$pc[\$clog2(M4_NUM_INSTRS+1)+1:2]\];
      
      \viz_alpha
         initEach() {
            let imem_header = new fabric.Text("📒 Instr. Memory", {
                  top: -29,
                  left: -440,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let decode_header = new fabric.Text("💭 Instr. Decode", {
                  top: 0,
                  left: 40,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let rf_header = new fabric.Text("🗃️ Reg. File", {
                  top: -29 - 40,
                  left: 280,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let dmem_header = new fabric.Text("📂 Data Memory", {
                  top: -29 - 40,
                  left: 450,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let error_header = new fabric.Text("🚨 Missing Signals", {
                  top: 350,
                  left: -400,
                  fontSize: 18,
                  fontWeight: 800,
                  fill: "red",
                  fontFamily: "monospace"
               })
            let error_box   = new fabric.Rect({
                  top: 400,
                  left: -500,
                  fill: "#ffffe0",
                  width: 400,
                  height: 300,
                  stroke: "black"
               })
            return {objects: {imem_header, decode_header, rf_header, dmem_header, error_header, error_box}};
         },
         renderEach: function() {
            //debugger
            //
            // PC instr_mem pointer
            let pc            = this.svSigRef(`L0_pc_a0`);
            let rd_valid      = this.svSigRef(`L0_rd_valid_a0`);
            let rd            = this.svSigRef(`L0_rd_a0`);
            let result        = this.svSigRef(`L0_result_a0`);
            let src1_value    = this.svSigRef(`L0_src1_value_a0`);
            let src2_value    = this.svSigRef(`L0_src2_value_a0`);
            let imm           = this.svSigRef(`L0_imm_a0`);
            let imm_valid     = this.svSigRef(`L0_imm_valid_a0`);
            let rs1           = this.svSigRef(`L0_rs1_a0`);
            let rs2           = this.svSigRef(`L0_rs2_a0`);
            let rs1_valid     = this.svSigRef(`L0_rs1_valid_a0`);
            let rs2_valid     = this.svSigRef(`L0_rs2_valid_a0`);
            let valid         = this.svSigRef(`L0_valid_a0`);
            let mnemonic      = this.svSigRef(`L0_mnemonic_a0`);
            let rf_wr_data    = this.svSigRef(`L0_rf_wr_data_a0`);
            
            var missing_list = "";
            
            if (examp   == null){
               missing_list += "◾ $example    \n";
               examp    = '$sticky_zero';
            }
            if (pc         == null){
               missing_list += "◾ $pc         \n";
               pc         = '$sticky_zero';
            }
            if (rd_valid   == null){
               missing_list += "◾ $rd_valid   \n";
               rd_valid   = '$sticky_zero';
            }
            if (rd         == null){
               missing_list += "◾ $rd         \n";
               rd         = '$sticky_zero';
            }
            if (result     == null){
               missing_list += "◾ $result     \n";
               result     = '$sticky_zero';
            }
            if (src1_value == null){
               missing_list += "◾ $src1_value \n";
               src1_value = '$sticky_zero';
            }
            if (src2_value == null){
               missing_list += "◾ $src2_value \n";
               src2_value = '$sticky_zero';
            }
            if (imm        == null){
               missing_list += "◾ $imm        \n";
               imm        = '$sticky_zero';
            }
            if (imm_valid  == null){
               missing_list += "◾ $imm_valid  \n";
               imm_valid  = '$sticky_zero';
            }
            if (rs1        == null){
               missing_list += "◾ $rs1        \n";
               rs1        = '$sticky_zero';
            }
            if (rs2        == null){
               missing_list += "◾ $rs2        \n";
               rs2        = '$sticky_zero';
            }
            if (rs1_valid  == null){
               missing_list += "◾ $rs1_valid  \n";
               rs1_valid  = '$sticky_zero';
            }
            if (rs2_valid  == null){
               missing_list += "◾ $rs2_valid  \n";
               rs2_valid  = '$sticky_zero';
            }
            if (valid      == null){
               missing_list += "◾ $valid      \n";
               valid      = '$sticky_zero';
            }
            if (mnemonic   == null){
               missing_list += "◾ $mnemonic   \n";
               mnemonic   = '$sticky_zero';
            }
            if (rf_wr_data == null){
               missing_list += "◾ $rf_wr_data \n";
               rf_wr_data = '$sticky_zero';
            }
            
            let color = !(valid.asBool()) ? "gray" :
                                            "blue";
            
            let pcPointer = new fabric.Text("->", {
               top: 18 * (pc.asInt() / 4),
               left: -295,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            })
            let pc_arrow = new fabric.Line([23, 18 * (pc.asInt() / 4) + 6, 46, 35], {
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
            let ld_arrow = new fabric.Line([470, 18 * '$dmem_rd_index'.asInt() + 6 - 40, 370, 18 * '$rf_wr_index'.asInt() + 6 - 40], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: '$dmem_rd_en'.asBool()
            })
            let st_arrow = new fabric.Line([470, 18 * '$dmem_wr_index'.asInt() + 6 - 40, 370, 18 * '$rf_rd_index2'.asInt() + 6 - 40], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: '$dmem_wr_en'.asBool()
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
            let immStr = (valid, immValue) => {
               return valid ? `i[${immValue}]` : ``;
            };
            let srcStr = ($src, $valid, $reg, $value) => {
               return $valid.asBool(false)
                          ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                          : "";
            };
            
            let str = `${regStr(rd_valid.asBool(false), rd.asInt(NaN), result.asInt(NaN))}\n` +
                      `  = ${mnemonic.asString()}${srcStr(1, rs1_valid, rs1, src1_value)}${srcStr(2, rs2_valid, rs2, src2_value)}\n` +
                      `      ${immStr(imm_valid.asBool(false), imm.asInt(NaN))}`;
            let instrWithValues = new fabric.Text(str, {
               top: 70,
               left: 65,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            });
            // Animate fetch (and provide onChange behavior for other animation).
            
            let fetch_instr_viz = new fabric.Text('$fetch_instr_str'.asString(), {
               top: 18 * (pc.asInt() / 4),
               left: -272,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace"
            })
            fetch_instr_viz.animate({top: 32, left: 50}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            });
            
            let src1_value_viz = new fabric.Text(src1_value.asInt(0).toString(), {
               left: 316 + 8 * 4,
               top: 18 * rs1.asInt(0) - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: rs1_valid.asBool(false)
            })
            setTimeout(() => {src1_value_viz.animate({left: 166, top: 70 + 18 * 2}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            })}, 500)
            let src2_value_viz = new fabric.Text(src2_value.asInt(0).toString(), {
               left: 316 + 8 * 4,
               top: 18 * rs2.asInt(0) - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: rs2_valid.asBool(false)
            })
            setTimeout(() => {src2_value_viz.animate({left: 166, top: 70 + 18 * 3}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            })}, 500)
            
            let load_viz = new fabric.Text(rf_wr_data.asInt(0).toString(), {
               left: 470,
               top: 18 * '$dmem_rd_index'.asInt() + 6 - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 1000,
               visible: false
            })
            if ('$dmem_rd_en'.asBool()) {
               setTimeout(() => {
                  load_viz.setVisible(true)
                  load_viz.animate({left: 350, top: 18 * '$rf_wr_index'.asInt() - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            let store_viz = new fabric.Text(src2_value.asInt(0).toString(), {
               left: 350,
               top: 18 * '$rf_rd_index2'.asInt() - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 1000,
               visible: false
            })
            if ('$dmem_wr_en'.asBool()) {
               setTimeout(() => {
                  store_viz.setVisible(true)
                  store_viz.animate({left: 510, top: 18 * '$dmem_wr_index'.asInt() - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            let result_shadow = new fabric.Text(result.asInt(0).toString(), {
               left: 146,
               top: 70,
               fill: "#d0d0ff",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: false
            })
            let result_viz = new fabric.Text(result.asInt(0).toString(), {
               left: 146,
               top: 70,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: false
            })
            if (rd_valid.asBool() && !'$dmem_rd_en'.asBool()) {
               setTimeout(() => {
                  result_viz.setVisible(true)
                  result_shadow.setVisible(true)
                  result_viz.animate({left: 317 + 8 * 4, top: 18 * rd.asInt(0) - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            let missing_fill = new fabric.Text(missing_list, {
                  top: 420,
                  left: -480,
                  fontSize: 16,
                  fontWeight: 500,
                  fontFamily: "monospace",
                  fill: "purple"
               })
            
            return {objects: [pcPointer, pc_arrow, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr_viz, src1_value_viz, src2_value_viz, result_shadow, result_viz, ld_arrow, st_arrow, load_viz, store_viz, missing_fill]};
         }
      
      /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
         $rd_viz = !/top$reset && /top$pc[4:2] == #imem;
         $instr[31:0] = *instrs\[#imem\];
         $instr_str[40*8-1:0] = *instr_strs[imem];
         \viz_alpha
            initEach() {
              let binary = new fabric.Text("", {
                 top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                 left: -600,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              let disassembled = new fabric.Text("", {
                 top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                 left: -270,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              return {objects: {binary: binary, disassembled: disassembled}}
            },
            renderEach: function() {
               // Instruction memory is constant, so just create it once.
               if (!global.instr_mem_drawn) {
                  global.instr_mem_drawn = [];
               }
               if (!global.instr_mem_drawn[this.getIndex()]) {
                  global.instr_mem_drawn[this.getIndex()] = true
                  let binary_str       = '$instr'.asBinaryStr(NaN)
                  let disassembled_str = '$instr_str'.asString()
                  disassembled_str = disassembled_str.slice(0, -5)
                  //debugger
                  this.getInitObject("binary").setText(binary_str)
                  this.getInitObject("disassembled").setText(disassembled_str)
               }
               this.getInitObject("disassembled").set({textBackgroundColor: '$rd_viz'.asBool() ? "#b0ffff" : "white"})
            }
      
      /xreg[31:0]
         $ANY = /top/xreg<>0$ANY;
         $rd = (/cpuviz$rf_rd_en1 && /cpuviz$rf_rd_index1 == #xreg) ||
               (/cpuviz$rf_rd_en2 && /cpuviz$rf_rd_index2 == #xreg);
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
                  fontWeight: mod ? 1000 : 400,
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
         
      /dmem[31:0]
         $ANY = /top/dmem<>0$ANY;
         $rd = (/cpuviz$dmem_rd_en && /cpuviz$dmem_rd_index == #dmem);
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
               let dmem_str = new fabric.Text(regIdent + ": " + '>>1$value'.asInt(NaN).toString(), {
                  top: 18 * this.getIndex() - 40,
                  left: 480,
                  fontSize: 14,
                  fill: mod ? "blue" : "black",
                  fontWeight: mod ? 1000 : 400,
                  fontFamily: "monospace",
                  textBackgroundColor: rd ? "#b0ffff" : null
               })
               if (mod) {
                  setTimeout(() => {
                     console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                     dmem_str.set({text: newValStr, dirty: true})
                     this.global.canvas.renderAll()
                  }, 1500)
               }
               return {objects: [dmem_str]}
            }
   '])




\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
                   
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
   m4_asm(ADDI, r1, r0, 101)
   m4_asm(ORI, r6, r0, 0)
   m4_asm(SW, r6, r1, 0)
   m4_asm(LW, r4, r6, 0)
   // Optional:
   m4_asm(JAL, r7, 11111111111111100100) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   
   m4_define_hier(['M4_IMEM'], M4_NUM_INSTRS)
   m4+fill_imem()
   
   //|cpu
      //1 - PC
      //@1
   $reset = *reset;
   $next_pc[31:0] =  $reset    ? '0              :
                     $taken_br ? $br_tgt_pc   :  //9
                     $is_jal   ? $br_tgt_pc   :  // 13
                     $is_jalr  ? $jalr_tgt_pc :  // 13
                     $pc + 32'd4 ;
   $pc[31:0] = >>1$next_pc;
   
      //2 - IMEM - Read
      //@1
   `READONLY_MEM($pc, $$instr[31:0])

   //3 - Decode Logic - RISBUJ
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

   //4 - Instr Fields
   $funct7[6:0]   =  $instr[31:25];
   $funct3[2:0]   =  $instr[14:12];
   $rs1[4:0]      =  $instr[19:15];
   $rs2[4:0]      =  $instr[24:20];
   $rd[4:0]       =  $instr[11:7];
   $opcode[6:0]   =  $instr[6:0];
   `BOGUS_USE($funct7 $funct3 $rs1 $rs2 $rd $opcode)

   $funct7_valid  =  $is_r_instr;
   $funct3_valid  =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs1_valid     =  $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid     =  $is_r_instr || $is_s_instr || $is_b_instr ;
   $rd_valid      =  $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $imm_valid     =  $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   `BOGUS_USE($funct7_valid $funct3_valid $rs1_valid $rs2_valid $rd_valid $imm_valid)

   //5 - Imm 
   $imm[31:0]  =  $is_i_instr ?  {{21{$instr[31]}}, $instr[30:20]}                                  :
                  $is_s_instr ?  {{21{$instr[31]}}, $instr[30:25], $instr[11:7]}                    :
                  $is_b_instr ?  {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0}   :
                  $is_u_instr ?  {$instr[31:12], 12'b0}                                             :
                  $is_j_instr ?  {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                                 32'b0 ;
   `BOGUS_USE($imm)

   //6 - Decode Instr Name
   $dec_bits[10:0]   =  {$funct7[5], $funct3, $opcode};
   $is_beq           =  $dec_bits ==? 11'bx_000_1100011;
   $is_bne           =  $dec_bits ==? 11'bx_001_1100011;
   $is_blt           =  $dec_bits ==? 11'bx_100_1100011;
   $is_bge           =  $dec_bits ==? 11'bx_101_1100011;
   $is_bltu          =  $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu          =  $dec_bits ==? 11'bx_111_1100011;

   $is_addi          =  $dec_bits ==? 11'bx_000_0010011;
   $is_add           =  $dec_bits ==? 11'b0_000_0110011;
   `BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add)

   //7 - RF Read
   //$rf_rd_en1           =   $rs1_valid;
   //$rf_rd_index1[4:0]   =   $rs1;
   //$src1_value[31:0]    =   $rf_rd_data1;

   //$rf_rd_en2           =   $rs2_valid;
   //$rf_rd_index2[4:0]   =   $rs2;
   //$src2_value[31:0]    =   $rf_rd_data2;

   //`BOGUS_USE($src1_value $src2_value)

   //8 - ALU
   //$result[31:0] =   $is_addi ?  $src1_value + $imm :
   //                  $is_add  ?  $src1_value + $src2_value :
   //                              32'bx;
   $rf_wr_en            =     $rd_valid && ($rd != 5'b0);
   //$rf_wr_index[4:0]    =     $rd;
   $rf_wr_data[31:0]    =     $is_load ? $ld_data : $resulto; // 14

   //9- Branch
   $taken_br   =  $is_beq  ?  ($src1_value == $src2_value) :
                  $is_bne  ?  ($src1_value != $src2_value) :
                  $is_blt  ?  (($src1_value < $src2_value)  ^ ($src1_value[31] != $src2_value[31])) :
                  $is_bge  ?  (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                  $is_bltu ?  ($src1_value < $src2_value)  :
                  $is_bgeu ?  ($src1_value >= $src2_value) :
                              1'b0;

   $br_tgt_pc[31:0]  =  $pc + $imm;

   // 10 - Stop
   //*passed = |cpu/xreg[10]>>5$value == (1+2+3+4+5+6+7+8+9);

   //11
   $is_lui     =  $dec_bits ==? 11'bx_xxx_0110111 ;
   $is_auipc   =  $dec_bits ==? 11'bx_xxx_0010111 ;
   $is_jal     =  $dec_bits ==? 11'bx_xxx_1101111 ;
   $is_jalr    =  $dec_bits ==? 11'bx_000_1100111 ;

   $is_load    =  $opcode   ==  7'b0000011        ;

   $is_sb      =  $dec_bits ==? 11'bx_000_0100011 ;
   $is_sh      =  $dec_bits ==? 11'bx_001_0100011 ;
   $is_sw      =  $dec_bits ==? 11'bx_010_0100011 ;

   $is_slti    =  $dec_bits ==? 11'bx_010_0010011 ;

   //12
   $resulto[31:0]  =     $is_addi || $is_load || $is_s_instr ?  $src1_value + $imm : // 14
                        $is_add     ?  $src1_value + $src2_value :
                        $is_lui     ?  {$imm[31:12], 12'b0} :
                        $is_auipc   ?  $pc + $imm :
                        $is_jal     ?  $pc + 32'd4 :
                        $is_jalr    ?  $pc + 32'd4 :
                        $is_slti    ?  (($src1_value[31] == $imm[31]) ? $src1_value < $imm : {31'b0, $src1_value[31]}) :
                                       32'bx;
   //13
   $is_jump             =  $is_jal || $is_jalr;
   $jalr_tgt_pc[31:0]   =  $src1_value + $imm;
   $valid = 1'b1;
   

   //14
   //$dmem_wr_en          =   $is_s_instr;
   //$dmem_rd_en1         =   $is_load;
   //$dmem_rd_index1[4:0] =   $result[6:2];
   //$dmem_wr_index[4:0]  =   $result[6:2];
   //$dmem_wr_data[31:0]  =   $src2_value;
   //$ld_data[31:0]       =   $dmem_rd_data1;

   //*passed = |cpu/xreg[4]>>5$value == 0;
      // YOUR CODE HERE
      // ...

      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simula/toption (before Makerchip cycle limit).
   *passed = *cyc_cnt > 60;
   *failed = 1'b0;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   //|cpu
   m4+rf(32, 32, $reset, W, $rf_wr_en, $rd, $rf_wr_data, R, $rs1_valid, $rs1, $$src1_value[31:0], R, $rs2_valid, $rs2, $$src2_value[31:0])
   m4+dmem(32, 32, $reset, W, $is_s_instr, $resulto[6:2], $src2_value, R, $is_load, $resulto[6:2], $$ld_data[31:0])
   
   m4+cpu_viz()    // For visualisation, argument should be at least equal to the last stage of CPU logic
                       // @4 would work for all labs
\SV
   endmodule
