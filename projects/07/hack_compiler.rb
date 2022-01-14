class CompilerError < StandardError
end


class Parser

  # COMMANDS = {
  #   ''=>C_UNKNOWN,
  #   'and'=>C_ARITHMETIC,
  #   'add'=>C_ARITHMETIC,
  #   'eq'=>C_ARITHMETIC,
  #   'gt'=>C_ARITHMETIC,
  #   'lt'=>C_ARITHMETIC,
  #   'neg'=>=>C_ARITHMETIC,
  #   'not'=>C_ARITHMETIC,
  #   'or'=>C_ARITHMETIC,
  #   'pop'=>C_POP,
  #   'push'=>C_PUSH,
  #   'sub'=>C_ARITHMETIC
  # }

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

  def command_type
    if read.empty?
      Code::C_UNKNOWN
    else
      Code::COMMANDS[read.split[0]]['command_type']
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

  def initialize(read_file, write_file)
    @jump_counter = 0
    @parser = Parser.new(read_file)
    @write_file = write_file

    File.open(write_file, 'w') { |file| }
  end

  def compile
    while @parser.more_commands?
      case @parser.command_type

      when Code::C_PUSH
        write_pushpop('push', @parser.arg1, @parser.arg2)

      when Code::C_POP
        write_pushpop('pop', @parser.arg1, @parser.arg2)

      when Code::C_ARITHMETIC
        write_arithmetic(@parser.arg1)

      end

      @parser.advance
    end
  end

  def next_counter
    @jump_counter = @jump_counter + 1
    @jump_counter
  end

  def write_arithmetic(command)
    code = Code::COMMANDS[command]['command_code'] % { counter: next_counter }
    write_line(code)
  end

  def write_pushpop(command, segment, index)
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

    when 'local', 'argument', 'this', 'that'
      args = {
        register: Code::REGISTERS[@parser.arg1],
        offset: @parser.arg2
      }
      type = 'relative'
    end

    code = Code::COMMANDS[command]['command_code'][type] % args

    write_line(code)
  end

  def write_line(line)
    File.open(@write_file, 'a') { |file| file.puts(line) }
  end

end


Compiler.new(ARGV[0], ARGV[1]).compile
