\m4_TLV_version 1d: tl-x.org
\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)

   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/immutable/master/MYTH_workshop/risc-v_solutions.tlv'])
\TLV
   // For RISC-V solutions, comment the line below.
   //m4_define(['M4_CALCULATOR'], 1)
   // Provide a slide number for the lab.
   m4_define(['M4_SLIDE_NUM'], 100)



   // Default Makerchip TL-Verilog Code Template
   m4_include_makerchip_hidden(['myth_workshop_solutions.private.tlv'])

\TLV
   m4+hidden_solution(1000)
   // The stage that is represented by visualization.
   m4+cpu_viz(@4)

   
   *failed = 1'b0;
\SV
   endmodule
