module sseg_decoder(output logic [6:0] sseg, input logic [3:0] digit);
   assign sseg = ~ (
        (digit == 0) ? 7'b1000000 : // '0'
        (digit == 1) ? 7'b1111001 : // '1'
        (digit == 2) ? 7'b0100100 : // '2'
        (digit == 3) ? 7'b0110000 : // '3'
        (digit == 4) ? 7'b0011001 : // '4'
        (digit == 5) ? 7'b0010010 : // '5'
        (digit == 6) ? 7'b0000010 : // '6'
        (digit == 7) ? 7'b1111000 : // '7'
        (digit == 8) ? 7'b0000000 : // '8'
        (digit == 9) ? 7'b0010000 : // '9'
        (digit == 10) ? 7'b0001000 : // 'a'
        (digit == 11) ? 7'b0000011 : // 'b'
        (digit == 12) ? 7'b1000110 : // 'c'
        (digit == 13) ? 7'b0100001 : // 'd'
        (digit == 14) ? 7'b0000110 : // 'e'
        (digit == 15) ? 7'b0001110 : // 'f'
                        7'b1111111 ) ; // 'nothing'
endmodule
