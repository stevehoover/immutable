\m4_TLV_version 1d: tl-x.org
\SV

   // =========================================
   // Welcome!  Try the tutorials via the menu.
   // =========================================

   // Default Makerchip TL-Verilog Code Template
   
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)

   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/master/tlv_lib/calculator_shell_lib.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/immutable/master/MYTH_workshop/calculator_solutions.tlv'])
\TLV
   $reset = *reset;

   m4+hidden_solution(1000)
   
   *failed = 1'b0;
\SV
   endmodule
