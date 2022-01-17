class CompilerError < StandardError
end


class Parser

  def initialize(vm_path)
    @vm_file = File.readlines(vm_path, chomp: true)
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

end


class Code

  C_ARITHMETIC = 'C_ARITHMETIC'
  C_GOTO = 'C_GOTO'
  C_LABEL = 'C_LABEL'
  C_POP = 'C_POP'
  C_PUSH = 'C_PUSH'
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
    @directory = File.dirname(read_file)
    @current_function = nil

    if File.directory?(read_file)
    else
      @base_name = File.basename(read_file, ".vm")
      @parser = Parser.new(read_file)
    end

    @write_file = File.join(@directory, "#{@base_name}.asm")
    File.open(@write_file, 'w') { |file| }
  end

  def compile
    while @parser.more_commands?
      case @parser.command_type

      when Code::C_ARITHMETIC
        write_arithmetic

      when Code::C_GOTO, Code::C_LABEL
        write_labelgoto

      when Code::C_POP, Code::C_PUSH
        write_pushpop

      end

      @parser.advance
    end
  end

  def next_counter
    @jump_counter = @jump_counter + 1
    @jump_counter
  end

  def write_arithmetic
    code = Code::COMMANDS[@parser.command]['command_code'] % { counter: next_counter }
    write_line(code)
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
        register: "#{@base_name}.#{@parser.arg2}"
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

  def write_line(line)
    File.open(@write_file, 'a') { |file| file.puts(line) }
  end

end


Compiler.new(ARGV[0]).compile
