// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)
//
// This program only needs to handle arguments that satisfy
// R0 >= 0, R1 >= 0, and R0*R1 < 32768.

// Put your code here.

      @R1    // D-register = second variable
      D=M
      @i     // i = second variable
      M=D
      @prod  // prod=0
      M=0
(LOOP)
      @i     // D-register = i
      D=M
      @FINAL // Goto FINAL if D == 0
      D;JEQ
      @R0    // D-register = first variable
      D=M
      @prod  // prod = prod + first variable
      M=M+D
      @i     // i = i - 1
      M=M-1
      @LOOP  // Goto LOOP
      0;JMP
(FINAL)
      @prod  // D-register = prod
      D=M
      @R2    // output variable = D-register
      M=D

(END)        // END LOOP
      @END
      0;JMP
