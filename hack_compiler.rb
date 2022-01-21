class CompilerError < StandardError
end


class Parser

  def initialize(vm_path)
    @vm_file = File.readlines(vm_path, chomp: true)
    @vm_file_name = File.basename(vm_path, ".vm")
    @current_line = 0

    # Remove comments and strip whitespace
    @vm_file.collect!{ |line| line.split('//').fetch(0, '').strip }
  end

  def advance
    @current_line += 1
  end

  def arg1
    if command_type == Code::C_ARITHMETIC
      read.split[0]
    else
      read.split[1]
    end
  end

  def arg2
    read.split[2]
  end

  def command
    unless read.empty?
      read.split[0]
    end
  end

  def command_type
    if read.empty?
      Code::C_UNKNOWN
    else
      Code::COMMANDS[command]['command_type']
    end
  end

  def more_commands?
    @current_line != @vm_file.length
  end

  def read
    @vm_file[@current_line]
  end

  def reset
    @current_line = 0
  end

  def vm_file_name
    @vm_file_name
  end

end


class Code

  C_ARITHMETIC = 'C_ARITHMETIC'
  C_CALL = 'C_CALL'
  C_FUNCTION = 'C_FUNCTION'
  C_GOTO = 'C_GOTO'
  C_LABEL = 'C_LABEL'
  C_POP = 'C_POP'
  C_PUSH = 'C_PUSH'
  C_RETURN = 'C_RETURN'
  C_UNKNOWN = 'C_UNKNOWN'

  COMMANDS = {
    'and'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        M=D&M
        @SP
        M=M+1
      EOS
    },
    'add'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        M=D+M
        @SP
        M=M+1
      EOS
    },
    'call'=>{
      'command_type'=>C_CALL,
      'command_code'=><<~EOS
        @RET_%{counter}
        D=A
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @LCL
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @ARG
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @THIS
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @THAT
        D=M
        @SP
        A=M
        M=D
        @SP
        MD=M+1
        @LCL
        M=D
        @%{offset}
        D=D-A
        @ARG
        M=D
        @%{target}
        0;JMP
        (RET_%{counter})
      EOS
    },
    'eq'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        D=M-D
        @IF_%{counter}
        D;JEQ
        @SP
        A=M
        M=0
        @END_%{counter}
        0;JMP
        (IF_%{counter})
        @SP
        A=M
        M=-1
        (END_%{counter})
        @SP
        M=M+1
      EOS
    },
    'function'=>{
      'command_type'=>C_FUNCTION
    },
    'goto'=>{
      'command_type'=>C_GOTO,
      'command_code'=><<~EOS
        @%{label}
        0;JMP
      EOS
    },
    'gt'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        D=M-D
        @IF_%{counter}
        D;JGT
        @SP
        A=M
        M=0
        @END_%{counter}
        0;JMP
        (IF_%{counter})
        @SP
        A=M
        M=-1
        (END_%{counter})
        @SP
        M=M+1
      EOS
    },
    'header'=>{
      'command_code'=><<~EOS
        @256
        D=A
        @SP
        M=D
      EOS
    },
    'if-goto'=>{
      'command_type'=>C_GOTO,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @%{label}
        D;JNE
      EOS
    },
    'label'=>{
      'command_type'=>C_LABEL,
      'command_code'=><<~EOS
        (%{label})
      EOS
    },
    'lt'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        D=M-D
        @IF_%{counter}
        D;JLT
        @SP
        A=M
        M=0
        @END_%{counter}
        0;JMP
        (IF_%{counter})
        @SP
        A=M
        M=-1
        (END_%{counter})
        @SP
        M=M+1
      EOS
    },
    'neg'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        M=-M
        @SP
        M=M+1
      EOS
    },
    'not'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        M=!M
        @SP
        M=M+1
      EOS
    },
    'or'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        M=D|M
        @SP
        M=M+1
      EOS
    },
    'pop'=>{
      'command_type'=>C_POP,
      'command_code'=>{
        'global'=><<~EOS,
          @SP
          AM=M-1
          D=M
          @%{register}
          M=D
        EOS
        'relative'=><<~EOS,
          @%{offset}
          D=A
          @%{register}
          D=M+D
          @13
          M=D
          @SP
          AM=M-1
          D=M
          @13
          A=M
          M=D
        EOS
      }
    },
    'push'=>{
      'command_type'=>C_PUSH,
      'command_code'=>{
        'constant'=><<~EOS,
          @%{constant}
          D=A
          @SP
          A=M
          M=D
          @SP
          M=M+1
        EOS
        'global'=><<~EOS,
          @%{register}
          D=M
          @SP
          A=M
          M=D
          @SP
          M=M+1
        EOS
        'relative'=><<~EOS,
          @%{offset}
          D=A
          @%{register}
          A=M+D
          D=M
          @SP
          A=M
          M=D
          @SP
          M=M+1
        EOS
      }
    },
    'return'=>{
      'command_type'=>C_RETURN,
      'command_code'=><<~EOS
        @LCL
        D=M
        @FRAME
        M=D
        @5
        A=D-A
        D=M
        @RET
        M=D
        @SP
        A=M-1
        D=M
        @ARG
        A=M
        M=D
        @ARG
        D=M
        @SP
        M=D+1
        @FRAME
        AM=M-1
        D=M
        @THAT
        M=D
        @FRAME
        AM=M-1
        D=M
        @THIS
        M=D
        @FRAME
        AM=M-1
        D=M
        @ARG
        M=D
        @FRAME
        AM=M-1
        D=M
        @LCL
        M=D
        @RET
        A=M
        0;JMP
      EOS
    },
    'sub'=>{
      'command_type'=>C_ARITHMETIC,
      'command_code'=><<~EOS
        @SP
        AM=M-1
        D=M
        @SP
        AM=M-1
        M=M-D
        @SP
        M=M+1
      EOS
    },
  }

  REGISTERS = {
    'local'=>'LCL',
    'argument'=>'ARG',
    'this'=>'THIS',
    'that'=>'THAT',
    'pointer'=>'3',
    'temp'=>'5'
  }

end


class Compiler

  def initialize(read_file)
    @jump_counter = 0
    @current_function = nil

    if File.directory?(read_file)
      @base_name = File.basename(read_file)
      @directory = read_file
      @parsers = Dir[File.join(read_file, "*.vm")].collect{ |p| Parser.new(p) }
    else
      @base_name = File.basename(read_file, ".vm")
      @directory = File.dirname(read_file)
      @parsers = [Parser.new(read_file)]
    end

    @write_file = File.join(@directory, "#{@base_name}.asm")
    File.open(@write_file, 'w') { |file| }
  end

  def compile
    write_header

    @parsers.each do |parser|
      @parser = parser
      while @parser.more_commands?
        case @parser.command_type

        when Code::C_ARITHMETIC
          write_arithmetic

        when Code::C_CALL
          write_call

        when Code::C_FUNCTION
          @current_function = @parser.arg1
          write_function

        when Code::C_GOTO, Code::C_LABEL
          write_labelgoto

        when Code::C_POP, Code::C_PUSH
          write_pushpop

        when Code::C_RETURN
          write_return
        end

        @parser.advance
      end
    end
  end

  def next_counter
    @jump_counter = @jump_counter + 1
    @jump_counter
  end

  def write_arithmetic
    args = {
      counter: next_counter
    }

    code = Code::COMMANDS[@parser.command]['command_code'] % args
    write_line(code)
  end

  def write_call
    args = {
      counter: next_counter,
      offset: @parser.arg2.to_i + 5,
      target: @parser.arg1
    }

    code = Code::COMMANDS['call']['command_code'] % args
    write_line(code)
  end

  def write_function
    header = Code::COMMANDS['label']['command_code'] % { label: @parser.arg1 }
    write_line(header)

    @parser.arg2.to_i.times do
      args = {
        constant: 0
      }

      body = Code::COMMANDS['push']['command_code']['constant'] % args
      write_line(body)
    end
  end

  def write_labelgoto
    if @current_function.nil?
      args = {
        label: @parser.arg1
      }
    else
      args = {
        label: "#{@current_function}:#{@parser.arg1}"
      }
    end

    code = Code::COMMANDS[@parser.command]['command_code'] % args
    write_line(code)
  end

  def write_pushpop
    case @parser.arg1

    when 'constant'
      args = {
        constant: @parser.arg2
      }
      type = 'constant'

    when 'pointer', 'temp'
      args = {
        register: Code::REGISTERS[@parser.arg1].to_i + @parser.arg2.to_i
      }
      type = 'global'

    when 'static'
      args = {
        register: "#{@parser.vm_file_name}.#{@parser.arg2}"
      }
      type = 'global'

    when 'local', 'argument', 'this', 'that'
      args = {
        register: Code::REGISTERS[@parser.arg1],
        offset: @parser.arg2
      }
      type = 'relative'
    end

    code = Code::COMMANDS[@parser.command]['command_code'][type] % args
    write_line(code)
  end

  def write_return
    code = Code::COMMANDS['return']['command_code']
    write_line(code)
  end

  def write_header
    code = Code::COMMANDS['header']['command_code']
    write_line(code)

    args = {
      counter: next_counter,
      offset: 0,
      target: 'Sys.init'
    }
    code = Code::COMMANDS['call']['command_code'] % args
    write_line(code)
  end

  def write_line(line)
    File.open(@write_file, 'a') { |file| file.puts(line) }
  end

end


Compiler.new(ARGV[0]).compile
