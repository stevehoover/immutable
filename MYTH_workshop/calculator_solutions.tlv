\m4_TLV_version 1d: tl-x.org
\SV
m4+definitions(['
   m4_define(['m4_lab'], ['m4_define(['m4_slide_cnt'], m4_eval(m4_slide_cnt + $1))m4_ifelse_block(m4_eval(m4_slide_cnt <= m4_slide), 1, ['['// Lab for slide ']m4_slide_cnt[': ']$2'])'])
   //// If not m4_pipelined, m4_stage(@#) will evaluate to @1.
   //m4_define(['m4_stage'], ['m4_ifelse(m4_pipelined, 0, @1, $1)'])
   //m4_define(['m4_pipelined'], 0)
'])
      
\TLV hidden_solution(_slide_num)
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/vineet/tlv_lib/calculator_shell_lib.tlv'])

      // ============================================================================================================
      // Solutions: Cut this section to provide the shell.
      
      m4_define(['m4_slide'], _slide_num)  // Build core for this slide
      
      m4_define(['m4_slide_cnt'], 0)  // Increments by the given number of slides for each lab.
      // Define the logic that will be included, based on slide number (specified as slide deltas between labs so editing is easier if slides are added).
      
\TLV
   |calc
      m4_lab(24, ['Sequentail Calculator
      m4_define(['m4_lab_6'], 1)
      '])
      m4_lab(12, ['Counter and Calculator in Pipeline
      m4_define(['m4_lab_8'], 1)
      '])
      m4_lab(1, ['Cycle Calculator
      m4_define(['m4_lab_9'], 1)
      '])
      m4_lab(4, ['Cycle Calculator with Validity
      m4_define(['m4_lab_10'], 1)
      '])
      m4_lab(1, ['Calculator with Single-Value Memory
      m4_define(['m4_lab_11'], 1)
      '])
      m4_lab(5, ['Calculator with Memory
      m4_define(['m4_lab_12'], 1)
      '])
      
      m4_ifelse_block(m4_lab_9, 1, ['
      m4_define(['M4_INPUT_STAGE'], 1)'], m4_lab_8, 1, ['
      m4_define(['M4_INPUT_STAGE'], 1)'], m4_lab_6, 1, ['
      m4_define(['M4_INPUT_STAGE'], 0)'])
      
      m4_ifelse_block(m4_lab_9, 1, ['
      m4_define(['M4_OUTPUT_STAGE'], 2)'], m4_lab_8, 1, ['
      m4_define(['M4_OUTPUT_STAGE'], 1)'], m4_lab_6, 1, ['
      m4_define(['M4_OUTPUT_STAGE'], 0)'])
      
      @M4_INPUT_STAGE
         m4_ifelse_block(m4_lab_6, 1, ['
         $reset = *reset;
         $val1[31:0] = >>m4_eval(M4_OUTPUT_STAGE - M4_INPUT_STAGE + 1)$out;
         $val2[31:0] = $rand2[3:0]; m4_ifelse_block(m4_lab_10, 1, ['
         $op1[2:0] = $rand_op[2:0];
         '], m4_lab_6, 1, ['
         $op1[1:0] = $rand_op[1:0];
         '])
         m4_ifelse_block(m4_lab_10, 1, ['
         $valid = $reset ? 1'b0 : >>1$valid + 1'b1;
         $reset_or_valid = $valid || $reset;
         '])
         '])
         m4_ifelse_block(m4_lab_12, 1, ['
         /mem_array[7:0]
            $wr = (#mem_array == |calc$val1[2:0]) && (|calc$op1 == 3'b101) && |calc$valid;
            $value[31:0] = |calc$reset ? 32'b0 :
                           $wr         ? |calc$mem :
                                          $RETAIN;
         '])
         m4_ifelse_block(m4_lab_11, 1, ['
         $mem[31:0] = >>2$out;
         '])
      m4_ifelse_block(m4_lab_11, 1, ['
      @M4_OUTPUT_STAGE
         $recall[31:0] = m4_ifelse(m4_lab_12, 1, [''], ['$reset           ? 32'b0 :'])
                         ($op1 == 3'b101) ? m4_ifelse(m4_lab_12, 1, ['/mem_array[$val1[2:0]]$value :'], ['$mem :'])
                                            >>1$recall;
         '])
      m4_ifelse_block(m4_lab_10, 1, ['
      ?$reset_or_valid
         @M4_INPUT_STAGE
            $sum[31:0] = $val1 + $val2;
            $diff[31:0] = $val1 - $val2;
            $prod[31:0] = $val1 * $val2;
            $quot[31:0] = $val1 / $val2;
         @M4_OUTPUT_STAGE
            $out[31:0] = $reset           ? 32'b0 :
                         ($op1 == m4_ifelse(m4_lab_11, 1, ['3'b000'], m4_lab_10, 1, ['2'b00'])) ? $sum  :
                         ($op1 == m4_ifelse(m4_lab_11, 1, ['3'b001'], m4_lab_10, 1, ['2'b01'])) ? $diff :
                         ($op1 == m4_ifelse(m4_lab_11, 1, ['3'b010'], m4_lab_10, 1, ['2'b10'])) ? $prod :
                         m4_ifelse(m4_lab_11, 1, ['($op1 == 3'b010) ? $quot :'], m4_lab_10, 1, ['$quot;']) m4_ifelse_block(m4_lab_11, 1, ['
                         ($op1 == 3'b100) ? $recall : 32'b0;'])
      '], m4_lab_6, 1, ['
      @M4_INPUT_STAGE
         $sum[31:0] = $val1 + $val2;
         $diff[31:0] = $val1 - $val2;
         $prod[31:0] = $val1 * $val2;
         $quot[31:0] = $val1 / $val2;
         m4_ifelse_block(m4_lab_10, 1, [''], m4_lab_9, 1, ['
         $valid = $reset ? 1'b0 : >>1$valid + 1'b1;'])
      @M4_OUTPUT_STAGE
         $out[31:0] = m4_ifelse(m4_lab_9, 1, ['$reset || !$valid'], m4_lab_6, 1, ['$reset']) ? 32'b0 :
                        ($op1 == 2'b00) ? $sum  :
                        ($op1 == 2'b01) ? $diff :
                        ($op1 == 2'b10) ? $prod :
                                          $quot;
         m4_ifelse_block(m4_lab_9, 1, [''], m4_lab_8, 1, ['
         $cnt[31:0] = $reset ? 1'b0 : >>1$cnt + 1'b1;'])
      '])
\TLV 
   |calc
      @2
         m4_ifelse_block(m4_lab_10, 1, ['
         // Needed for viz
         $issum = $valid && ($op1[2:0] == 3'b000);
         $ismin = $valid && ($op1[2:0] == 3'b001);
         $isprod = $valid && ($op1[2:0] == 3'b010);
         $isquot = $valid && ($op1[2:0] == 3'b011);
         $is_invalid_op = $valid && ($op1[2:0] == 3'b110);
         '])
         m4_ifelse_block(m4_lab_11, 1, ['
         $ismem = $valid && ($op1[2:0] == 3'b101);
         $isrecall = $valid && ($op1[2:0] == 3'b100);
         '])
         m4_ifelse_block(m4_lab_10, 1, ['
         $val1t = ($valid m4_ifelse(m4_lab_11, 1, ['&& !$isrecall']) && !$is_invalid_op);
         //$val1_modi[31:0] = ($val1 > ((1 << 31) - 1)) ? (~$val1 + 1) : $val1;
         $val2t = ($valid m4_ifelse(m4_lab_11, 1, ['&& !$isrecall']) && !$is_invalid_op);
         $outt  = ($valid && ($out_modified || !(|$out_modified))) && !$is_invalid_op;
         //$memt  = $valid && !$is_invalid_op;
         $out_modified[31:0] = ($out > ((1 << 31) - 1)) ? (~$out + 1) : $out;
         $isnegnum = ($out > ((1 << 31) - 1));
         '])
         m4_ifelse_block(m4_lab_12, 1, ['
         /mem_array[7:0]
            \viz_alpha
               initEach: function() {
                     let regs = new fabric.Text("",{
                              top: (25 * this.getIndex()) + 210,
                              left: 35,
                             fontSize: 14,
                             fontFamily: "monospace",
                           });
                    let calarraybox = new fabric.Rect({
                          left: 20,
                          top: 160,
                          fill: "white",
                          width: 150 - 20,
                          height: 366 - 110,
                          stroke: "black",
                          strokeWidth: 1,
                        });
                    let regname = new fabric.Text("mem_array", {
                           top: 180,
                           left: 35,
                           fontSize: 14,
                           fontFamily: "monospace"
                        });
               return {objects: {calarraybox: calarraybox, regname: regname, regs: regs}};
               //return {objects: {regname: regname, regs: regs}};
               },
               renderEach: function() {
                     let mod = '$wr'.asBool(false) && ('|calc$val1[2:0]'.asInt(-1) == this.getScope("mem_array").index);
                     let regs = parseInt(this.getIndex());
                     let regIdent = regs.toString();
                     let oldValStr = mod ? `(${'$value'.asInt(NaN).toString()})` : "";
                     this.getInitObject("regs").setText(
                        regIdent + ": " +
                        '$value'.asInt(NaN).toString() + oldValStr);
                     this.getInitObject("regs").setFill(mod ? "blue" : "black");
                  } '])
         \viz_alpha
            initEach: function() {
            let calbox = new fabric.Rect({
              left: 150,
              top: 150,
              fill: "#eeeeeeff",
              width: 316,
              height: 366,
              stroke: "black",
              strokeWidth: 1,
            });
            let val1box = new fabric.Rect({
              left: 150 + 28,
              top: 150 + 83,
              fill: "#eeeeeeff",
              width: 254 + 14,
              height: 40,
              stroke: "black",
              strokeWidth: 1,
            });
            let val1num = new fabric.Text("", {
              left: 150 + 28 + 30,
              top: 150 + 89,
              fontSize: 22,
              fontFamily: "Times",
            });
            let val2box = new fabric.Rect({
              left: 150 + 187,
              top: 150 + 221,
              fill: "#eeeeeeff",
              width: 109,
              height: 40,
              stroke: "black",
              strokeWidth: 1,
            });
            let val2num = new fabric.Text("", {
              left: 150 + 187 + 1,
              top: 150 + 221 + 7,
              fontSize: 22,
              fontFamily: "Times",
            });
            let outbox = new fabric.Rect({
              left: 150 + 97,
              top: 150 + 300,
              fill: "#eeeeeeff",
              width: 199,
              height: 40,
              stroke: "black",
              strokeWidth: 1,
            });
            let outnum = new fabric.Text("", {
              left: 150 + 97 + 20,
              top: 150 + 300 + 8,
              fontSize: 22,
              fontFamily: "Times",
            });
            let outnegsign = new fabric.Text("-", {
              left: 150 + 97 + 8,
              top: 150 + 300 + 6,
              fontSize: 22,
              fontFamily: "Times",
              fill : "#eeeeeeff",
            });
            let equalname = new fabric.Text("=", {
              left: 150 + 38,
              top: 150 + 306,
              fontSize: 28,
              fontFamily: "Times",
            }); m4_ifelse_block(m4_lab_10, 1, ['
              let sumbox = new fabric.Rect({
              left: 150 + 28,
              top: 150 + 148,
              fill: "#eeeeeeff",
              //fill: colorsum,
              width: 64,
              height: 64,
              stroke: "black",
              strokeWidth: 1
            });
            let prodbox = new fabric.Rect({
              left: 150 + 28,
              top: 150 + 222,
              fill: "#eeeeeeff",
              //fill: colorprod,
              width: 64,
              height: 64,
              stroke: "black",
              strokeWidth: 1
            });
            let minbox = new fabric.Rect({
              left: 150 + 105,
              top: 150 + 148,
              fill: "#eeeeeeff",
              //fill: colormin,
              width: 64,
              height: 64,
              stroke: "black",
              strokeWidth: 1
            });
            let quotbox = new fabric.Rect({
              left: 150 + 105,
              top: 150 + 222,
              fill: "#eeeeeeff",
              //fill: colorquot,
              width: 64,
              height: 64,
              stroke: "black",
              strokeWidth: 1
            });
            let sumicon = new fabric.Text("+", {
              left: 150 + 28 + 26,
              top: 150 + 148 + 22,
              fontSize: 22,
              fontFamily: "Times",
            });
            let prodicon = new fabric.Text("*", {
              left: 150 + 28 + 26,
              top: 150 + 222 + 22,
              fontSize: 22,
              fontFamily: "Times",
            });
            let minicon = new fabric.Text("-", {
              left: 150 + 105 + 26,
              top: 150 + 148 + 22,
              fontSize: 22,
              fontFamily: "Times",
            });
            let quoticon = new fabric.Text("/", {
              left: 150 + 105 + 26,
              top: 150 + 222 + 22,
              fontSize: 22,
              fontFamily: "Times",
            });
         ']) m4_ifelse_block(m4_lab_11, 1, ['
              let membox = new fabric.Rect({
              left: 105 + 150,
              top: 150 + 25,
              fill: "#eeeeeeff",
              width: 191,
              height: 23,
              stroke: "black",
              strokeWidth: 1,
            });
            let memname = new fabric.Text("mem", {
              left: 150 + 28,
              top: 150 + 25,
              fontSize: 22,
              fontFamily: "Times",
            });
            let memarrow = new fabric.Text("->", {
              left: 150 + 32 + 47,
              top: 150 + 25,
              fill: "#eeeeeeff",
              fontSize: 22,
              fontFamily: "monospace",
            });
            let recallarrow = new fabric.Text("->", {
              left: 150 + 38 + 28,
              top: 150 + 308,
              fill: "#eeeeeeff",
              fontSize: 22,
              fontFamily: "monospace",
            });
            let memnum = new fabric.Text("", {
              left: 150 + 105 + 30,
              top: 150 + 25,
              fontSize: 22,
              fontFamily: "Times",
            });
            let membuttonbox = new fabric.Rect({
              left: 150 + 187,
              top: 150 + 151, //fixed
              fill: "#eeeeeeff",
              width: 45,
              height: 40,
              stroke: "black",
              strokeWidth: 1
            });
            let recallbuttonbox = new fabric.Rect({
              left: 150 + 245,
              top: 150 + 151, //fixed
              fill: "#eeeeeeff",
              width: 51,
              height: 40, //fixed
              stroke: "black",
              strokeWidth: 1
            });
            let membuttonname = new fabric.Text("mem", {
              left: 150 + 187 + 1,
              top: 150 + 151 + 7,
              fontSize: 22,
              fontFamily: "Times",
            });
            let recallbuttonname = new fabric.Text("recall", {
              left: 150 + 245 + 1,
              top: 150 + 151 + 7,
              fontSize: 22,
              fontFamily: "Times",
            });'])  m4_ifelse_block(m4_lab_11, 1, ['
            return {objects: {calbox: calbox, val1box: val1box, val1num: val1num, val2box: val2box, val2num: val2num, outbox: outbox, outnum: outnum, equalname: equalname, sumbox: sumbox, minbox: minbox, prodbox: prodbox, quotbox: quotbox, sumicon: sumicon, prodicon: prodicon, minicon: minicon, quoticon: quoticon, outnegsign: outnegsign,  membox: membox, memname: memname, memnum: memnum, membuttonbox: membuttonbox, recallbuttonbox: recallbuttonbox, membuttonname: membuttonname, recallbuttonname: recallbuttonname, memarrow: memarrow, recallarrow: recallarrow}};'], m4_lab_10, 1, ['
            return {objects: {calbox: calbox, val1box: val1box, val1num: val1num, val2box: val2box, val2num: val2num, outbox: outbox, outnum: outnum, equalname: equalname, sumbox: sumbox, minbox: minbox, prodbox: prodbox, quotbox: quotbox, sumicon: sumicon, prodicon: prodicon, minicon: minicon, quoticon: quoticon, outnegsign: outnegsign}};'])
            },
            renderEach: function() {
               let colorsum =  '$issum'.asBool(false);
               let colorprod = '$isprod'.asBool(false);
               let colormin = '$ismin'.asBool(false);
               let colorquot = '$isquot'.asBool(false);m4_ifelse_block(m4_lab_11, 1, ['
               let colormembutton = '$ismem'.asBool(false);
               let colorrecallbutton = '$isrecall'.asBool(false);
               let colormemarrow = '$ismem'.asBool(false);
               let colorrecallarrow = '$isrecall'.asBool(false);
               let recallmod = '$isrecall'.asBool(false);'])
               let val1mod = '$val1t'.asBool(false);
               let val2mod = '$val2t'.asBool(false);
               let outmod = '$outt'.asBool(false);
               let colornegnum = '$isnegnum'.asBool(false);
               //let oldvalval1 = val1mod ? `(${'$val1'.asInt(NaN).toString()})` : "";
               //let oldvalval2 = val2mod ? `(${'$val2'.asInt(NaN).toString()})` : "";
               //let oldvalout = outmod ? `(${'$out'.asInt(NaN).toString()})` : "";
               //let oldvalrecall = recallmod ? `(${'$recall'.asInt(NaN).toString()})` : "";
               let oldvalval1 = "";
               let oldvalval2 = "";
               let oldvalout = "";
               let oldvalrecall = "";
               this.getInitObject("val1num").setText(
                  '$val1'.asInt(NaN).toString() + oldvalval1);
               this.getInitObject("val1num").setFill(val1mod ? "blue" : "grey");
               this.getInitObject("val2num").setText(
                  '$val2'.asInt(NaN).toString() + oldvalval2);
               this.getInitObject("val2num").setFill(val2mod ? "blue" : "grey");
               this.getInitObject("outnum").setText(
                  '$out_modified'.asInt(NaN).toString() + oldvalout);
               this.getInitObject("outnum").setFill(outmod ? "blue" : "grey");m4_ifelse_block(m4_lab_11, 1, ['
               this.getInitObject("memnum").setText(
                  '$recall'.asInt(NaN).toString() + oldvalrecall);
               this.getInitObject("memnum").setFill(recallmod ? "blue" : "grey");'])
               this.getInitObject("outnegsign").setFill(colornegnum ?  "blue" : "#eeeeeeff");
               this.getInitObject("sumbox").setFill(colorsum ?  "#9fc5e8ff" : "#eeeeeeff");
               this.getInitObject("minbox").setFill(colormin ?  "#9fc5e8ff" : "#eeeeeeff");
               this.getInitObject("prodbox").setFill(colorprod ? "#9fc5e8ff" : "#eeeeeeff");
               this.getInitObject("quotbox").setFill(colorquot ?  "#9fc5e8ff" : "#eeeeeeff");
               this.getInitObject("membuttonbox").setFill(colormembutton ? "#9fc5e8ff" : "#eeeeeeff");
               this.getInitObject("recallbuttonbox").setFill(colorrecallbutton ?  "#9fc5e8ff" : "#eeeeeeff");
               this.getInitObject("memarrow").setFill(colormemarrow ? "blue" : "#eeeeeeff");
               this.getInitObject("recallarrow").setFill(colorrecallarrow ?  "blue" : "#eeeeeeff");
             }
   
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
