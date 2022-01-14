class ParserError < StandardError
end

class AssemblerError < StandardError
end


class Parser

  # A-instruction
  A_COMMAND = 'A_COMMAND'

  # C-instruction
  C_COMMAND = 'C_COMMAND'

  # Label
  L_COMMAND = 'L_COMMAND'

  # Unknown
  U_COMMAND = 'U_COMMAND'

  def initialize(asm_path)
    @asm_file = File.readlines(asm_path, chomp: true)
    @current_line = 0

    # Remove comments and strip whitespace
    @asm_file.collect!{ |line| line.split('//').fetch(0, '').strip }
  end

  def advance
    @current_line += 1
  end

  def command_type
    if read =~ /^@\S+$/
      A_COMMAND
    elsif read =~ /^(\w+=[\w!+-\\&|]+|\w+=[\w!+-\\&|]+;\w+|[\w!+-\\&|]+;\w+)$/
      C_COMMAND
    elsif read =~ /^\([^()\s]+\)$/
    # elsif read =~ /^\([\w!+-\.\\&|]+\)$/
      L_COMMAND
    else
      U_COMMAND
    end
  end

  def comp
    if command_type != C_COMMAND
      raise ParserError.new "Command type is not C_COMMAND"
    else
      read.split('=').last.split(';').first
    end
  end

  def dest
    if command_type != C_COMMAND
      raise ParserError.new "Command type is not C_COMMAND"
    elsif read.include?('=')
      read.split('=').first
    else
      return 'null'
    end
  end

  def jump
    if command_type != C_COMMAND
      raise ParserError.new "Command type is not C_COMMAND"
    elsif read.include?(';')
      read.split(';').last
    else
      return 'null'
    end

  end

  def more_commands?
    @current_line != @asm_file.length
  end

  def read
    @asm_file[@current_line]
  end

  def reset
    @current_line = 0
  end

  def symbol
    if command_type == A_COMMAND
      read[1..-1]
    elsif command_type == L_COMMAND
      read[1..-2]
    else
      raise ParserError.new "Command type is not A_COMMAND or L_COMMAND"
    end
  end
end


class Code
  COMP_MNEMONIC = {
    # a-bit = 0
    'D&A'=>'0000000',
    'D+A'=>'0000010',
    'A-D'=>'0000111',
    'D'=>'0001100',
    '!D'=>'0001101',
    'D-1'=>'0001110',
    'D-A'=>'0010011',
    'D|A'=>'0010101',
    'D+1'=>'0011111',
    '0'=>'0101010',
    'A'=>'0110000',
    '!A'=>'0110001',
    'A-1'=>'0110010',
    '-A'=>'0110011',
    'A+1'=>'0110111',
    '-1'=>'0111010',
    '1'=>'0111111',

    # a-bit = 1
    'D&M'=>'1000000',
    'D+M'=>'1000010',
    'M-D'=>'1000111',
    'D-M'=>'1010011',
    'D|M'=>'1010101',
    'M'=>'1110000',
    '!M'=>'1110001',
    'M-1'=>'1110010',
    '-M'=>'1110011',
    'M+1'=>'1110111',
  }

  JUMP_MNEMONIC = {
    'null'=>'000',
    'JGT'=>'001',
    'JEQ'=>'010',
    'JGE'=>'011',
    'JLT'=>'100',
    'JNE'=>'101',
    'JLE'=>'110',
    'JMP'=>'111'
  }

  def self.comp(mnemonic)
    if COMP_MNEMONIC.keys.include?(mnemonic)
      COMP_MNEMONIC[mnemonic]
    else
      raise ParserError.new "Comp mnemonic is not recognized: '#{mnemonic}'"
    end
  end

  def self.dest(mnemonic)
    d1 = mnemonic.include?('A') ? 1 : 0
    d2 = mnemonic.include?('D') ? 1 : 0
    d3 = mnemonic.include?('M') ? 1 : 0
    "#{d1}#{d2}#{d3}"
  end

  def self.jump(mnemonic)
    if JUMP_MNEMONIC.keys.include?(mnemonic)
      JUMP_MNEMONIC[mnemonic]
    else
      raise ParserError.new "Jump mnemonic is not recognized: #{mnemonic}"
    end
  end
end


class SymbolTable

  BUILTIN_SYMBOLS = {
    # Virtual registers
    'R0'=>'0',
    'R1'=>'1',
    'R2'=>'2',
    'R3'=>'3',
    'R4'=>'4',
    'R5'=>'5',
    'R6'=>'6',
    'R7'=>'7',
    'R8'=>'8',
    'R9'=>'9',
    'R10'=>'10',
    'R11'=>'11',
    'R12'=>'12',
    'R13'=>'13',
    'R14'=>'14',
    'R15'=>'15',

    # Predefined pointers
    'SP'=>'0',
    'LCL'=>'1',
    'ARG'=>'2',
    'THIS'=>'3',
    'THAT'=>'4',

    # I/O pointers
    'SCREEN'=>'16384',
    'KBD'=>'24576',
  }
  FIRST_VARIABLE_ADDRESS = 16

  def initialize
    @symbols = BUILTIN_SYMBOLS.clone
    @next_variable_address = FIRST_VARIABLE_ADDRESS
  end

  def add_label(symbol, address)
    @symbols[symbol] = address
  end

  def add_variable(symbol)
    @symbols[symbol] = @next_variable_address
    @next_variable_address += 1
  end

  def get_address(symbol)
    @symbols[symbol]
  end

  def include?(symbol)
    @symbols.keys.include?(symbol)
  end

end


class Assembler

  def initialize(read_file, write_file)
    @write_file = write_file
    @parser = Parser.new(read_file)
    @symbols = SymbolTable.new

    File.open(write_file, 'w') { |file| }
  end

  def assemble
    build_symbol_table
    @parser.reset
    parse_program
  end

  def build_symbol_table
    current_output_line = 0

    while @parser.more_commands?
      case @parser.command_type

      when Parser::L_COMMAND
        if @symbols.include?(@parser.symbol)
          raise AssemblerError.new "Label symbol already defined: #{@parser.symbol}"
        else
          @symbols.add_label(@parser.symbol, current_output_line)
        end

      when Parser::A_COMMAND, Parser::C_COMMAND
        current_output_line += 1

      end

      @parser.advance
    end
  end

  def parse_program
    while @parser.more_commands?
      case @parser.command_type

      when Parser::A_COMMAND
        if Integer(@parser.symbol, exception: false)
          line = '%016b' % @parser.symbol
        elsif @symbols.include?(@parser.symbol)
          line = '%016b' % @symbols.get_address(@parser.symbol)
        else
          @symbols.add_variable(@parser.symbol)
          line = '%016b' % @symbols.get_address(@parser.symbol)
        end

      when Parser::C_COMMAND
        comp = Code.comp(@parser.comp)
        dest = Code.dest(@parser.dest)
        jump = Code.jump(@parser.jump)
        line = "111#{comp}#{dest}#{jump}"

      end

      unless [Parser::U_COMMAND, Parser::L_COMMAND].include?(@parser.command_type)
        write_line(line)
      end

      @parser.advance
    end
  end

  def write_line(line)
    File.open(@write_file, 'a') { |file| file.puts(line) }
  end

end


Assembler.new(ARGV[0], ARGV[1]).assemble
