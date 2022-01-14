// push constant 7
@7     // D=7
D=A
@SP    // put D on stack
A=M
M=D
@SP    // advance stack pointer
M=M+1

// push constant 8
@8     // D=8
D=A
@SP    // put D on stack
A=M
M=D
@SP    // advance stack pointer
M=M+1

// add
@SP    // back up stack pointer
AM=M-1
D=M    // D=8
@SP    // back up stack pointer
AM=M-1
D=D+M  // D=D=7
M=D    // put D on stack
@SP    // advance stack pointer
M=M+1
