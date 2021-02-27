\m4_TLV_version 1d: tl-x.org
\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)

\TLV
   // For RISC-V solutions, comment the line below.
   //m4_define(['M4_CALCULATOR'], 1)
   // Provide a slide number for the lab.
   m4_define(['M4_SLIDE_NUM'], 100)


   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/immutable/master/MYTH_workshop/risc-v_solutions.tlv'])

\TLV
   m4+hidden_solution(M4_SLIDE_NUM)
   // The stage that is represented by visualization.
   m4+cpu_viz(@4)

\SV
   endmodule
