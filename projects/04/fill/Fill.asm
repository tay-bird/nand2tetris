// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed.
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.  -> 8192

(BEGIN)
      @KBD
      D=M
      @FLASH
      D;JNE
      @CLEAR
      0;JMP

(FLASH)
      D=0    // colour = all black
      @colour
      M=!D

      @FILL // Goto BEGIN
      0;JMP

(CLEAR)
      @colour// colour = all white
      M=0

      @FILL // Goto BEGIN
      0;JMP

(FILL)
      @SCREEN// D = SCREEN address
      D=A

      @spos  // spos = SCREEN address
      M=D

      @8192 // D-register = 8192 (screen address space)
      D=A

      @i    // i = 8192
      M=D

(LOOP)
      @colour// D-register = colour
      D=M

      @spos  // screen position set colour
      A=M
      M=D

      @i     // i = i - 1
      M=M-1

      @spos
      M=M+1

      @i    // D-register = i
      D=M

      @LOOP // Goto LOOP if i != 0
      D;JNE

      @BEGIN // Goto BEGIN
      0;JMP
