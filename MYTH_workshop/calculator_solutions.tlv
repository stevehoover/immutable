\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/vineet/tlv_lib/calculator_shell_lib.tlv?tag=']M4_UNIQUE_TAG)
m4+definitions(['
   m4_define(['m4_lab'], ['m4_define(['m4_slide_cnt'], m4_eval(m4_slide_cnt + $1))m4_ifelse_block(m4_eval(m4_slide_cnt <= m4_slide), 1, ['['// Lab for slide ']m4_slide_cnt[': ']$2'])'])
   //// If not m4_pipelined, m4_stage(@#) will evaluate to @1.
   //m4_define(['m4_stage'], ['m4_ifelse(m4_pipelined, 0, @1, $1)'])
   //m4_define(['m4_pipelined'], 0)



'])
\TLV hidden_solution(_slide_num)
      
   |calc
   
      // ============================================================================================================
      // Solutions: Cut this section to provide the shell.
      m4_define(['m4_slide'], _slide_num)  // Build core for this slide

      m4_define(['m4_slide_cnt'], 0)  // Increments by the given number of slides for each lab.
      // Define the logic that will be included, based on slide number (specified as slide deltas between labs so editing is easier if slides are added).


      m4_lab(23, ['Sequential Calculator
      m4_define(['m4_lab_6'], 1)
      '])
      m4_lab(12, ['Counter and Calculator in Pipeline
      m4_define(['m4_lab_8'], 1)
      '])
      m4_lab(1, ['Cycle Calculator
      m4_define(['m4_lab_9'], 1)
      '])
      m4_lab(5, ['Cycle Calculator with Validity
      m4_define(['m4_lab_10'], 1)
      '])
      m4_lab(2, ['Calculator with Single-Value Memory
      m4_define(['m4_lab_11'], 1)
      '])
      m4_lab(25, ['Calculator with Memory
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
      
      @0
         $reset = *reset;
      @M4_INPUT_STAGE
         m4_ifelse_block(m4_lab_6, 1, ['
         //$reset = *reset;
         $val1[31:0] = >>m4_eval(M4_OUTPUT_STAGE - M4_INPUT_STAGE + 1)$out;
         $val2[31:0] = $rand2[3:0];
         m4_ifelse_block(m4_lab_10, 1, ['
         $valid = $reset ? 1'b0 : >>1$valid + 1'b1;
         $reset_or_valid = $valid || $reset;
         '])
         '])

         m4_ifelse_block(m4_lab_12, 1, ['
         /mem_array[7:0]
            $wr = (#mem_array == |calc$val1[2:0]) && (|calc$op[2:0] == 3'b101) && |calc$valid;
            $value[31:0] = |calc$reset ? 32'b0 :
                           $wr         ? |calc>>2$out :
                                          $RETAIN;
         '])

      m4_ifelse_block(m4_lab_11, 1, ['
      @M4_OUTPUT_STAGE
         $mem[31:0] = m4_ifelse(m4_lab_12, 1, [''], ['$reset           ? 32'b0 :'])
                         ($op[2:0] == 3'b101) ? m4_ifelse(m4_lab_12, 1, ['/mem_array[$val1[2:0]]$value :'], ['$val1 :'])
                                            >>2$mem;
         '])
      m4_ifelse_block(m4_lab_10, 1, ['
      ?$reset_or_valid
         @M4_INPUT_STAGE
            //m4_rand($op, m4_ifelse(m4_lab_11, 1, ['2'], ['1']), 0)
            $sum[31:0] = $val1 + $val2;
            $diff[31:0] = $val1 - $val2;
            $prod[31:0] = $val1 * $val2;
            $quot[31:0] = $val1 / $val2;
         @M4_OUTPUT_STAGE
            $out[31:0] = $reset           ? 32'b0 :
                         ($op == m4_ifelse(m4_lab_11, 1, ['3'b000'], m4_lab_10, 1, ['2'b00'])) ? $sum  :
                         ($op == m4_ifelse(m4_lab_11, 1, ['3'b001'], m4_lab_10, 1, ['2'b01'])) ? $diff :
                         ($op == m4_ifelse(m4_lab_11, 1, ['3'b010'], m4_lab_10, 1, ['2'b10'])) ? $prod :
                         m4_ifelse(m4_lab_11, 1, ['($op == 3'b010) ? $quot :'], m4_lab_10, 1, ['$quot;']) m4_ifelse_block(m4_lab_11, 1, ['
                         ($op == 3'b100) ? $mem : >>1$out;'])
      '], m4_lab_6, 1, ['
      @M4_INPUT_STAGE
         //m4_rand($op, 1, 0)
         $sum[31:0] = $val1 + $val2;
         $diff[31:0] = $val1 - $val2;
         $prod[31:0] = $val1 * $val2;
         $quot[31:0] = $val1 / $val2;
         m4_ifelse_block(m4_lab_10, 1, [''], m4_lab_9, 1, ['
         $valid = $reset ? 1'b0 : >>1$valid + 1'b1;'])
      @M4_OUTPUT_STAGE
         $out[31:0] = m4_ifelse(m4_lab_9, 1, ['$reset || !$valid'], m4_lab_6, 1, ['$reset']) ? 32'b0 :
                        ($op[1:0] == 2'b00) ? $sum  :
                        ($op[1:0] == 2'b01) ? $diff :
                        ($op[1:0] == 2'b10) ? $prod :
                                              $quot;
         m4_ifelse_block(m4_lab_9, 1, [''], m4_lab_8, 1, ['
         $cnt[31:0] = $reset ? 1'b0 : >>1$cnt + 1'b1;'])
      '])
   m4+cal_viz(@M4_OUTPUT_STAGE)
   
   // ============================================================================================================
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;


\SV_plus
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   m4+main(1000)   // Slide number of model to build.
\SV_plus
   endmodule
