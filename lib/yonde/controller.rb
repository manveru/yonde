class Yonde
  # The Controller receives the input in chunks from pty, parses it, and invokes
  # the corresponding methods to manipulate the buffer.
  # It contains all of the logic, hopefully it ends up being buffer-agnostic.
  # For now, our buffer will be a Tk::Text, Tk::Canvas might be another option,
  # but after first trials it had very bad performance when the scrollback gets larger.
  # It was also a O(y*x) operation to insert or delete a line, where y is the
  # number of lines and x the width of the lines.
  # Not to mention difficulties with wrapping, which happens to be a very
  # important feature for me.
  #
  # The main issues with Tk::Text are related to random access indices, Tk
  # provides no easy way to make sure that e.g.
  # 10.10 exists, if indexed it simply equals end if the buffer is smaller than
  # this.
  # So I will use the behaviour of urxvt, and ignore all actions if the index is
  # out of bounds.
  # It would be nice to able to configure tk in that regard.
  # Also it's not trivial to index counting from the top-left of the current
  # view, but maybe we find a solution for that.
  class Controller < Struct.new(:buffer, :stack, :queue)
    CHANGE_SCROLL_REGION = /\A\e\[(\d+);(\d+)r/
    COLUMN_ADDRESS       = /\A\e\[(\d+)G/
    CURSOR_ADDRESS       = /\A\e\[(\d+);(\d+)H/
    ERASE_CHARS          = /\A\e\[(\d+)X/
    CURSOR_HOME          = /\A\e\[H/
    INITIALIZE_COLOR     = /\A\e\]([\d;]*)[m;]/
    PARM_DCH             = /\A\e\[(\d+)P/
    PARM_DOWN_CURSOR     = /\A\e\[(\d+)B/
    PARM_ICH             = /\A\e\[(\d+)@/
    PARM_LEFT_CURSOR     = /\A\e\[(\d+)D/
    PARM_RIGHT_CURSOR    = /\A\e\[(\d+)C/
    PARM_UP_CURSOR       = /\A\e\[(\d+)A/
    ROW_ADDRESS          = /\A\e\[(\d+)d/
    SET_A_BACKGROUND     = /\A\e\[48;5;(\d+)m/
    SET_A_FOREGROUND     = /\A\e\[38;5;(\d+)m/
    SET_BACKGROUND       = /\A\e\[\?([\d;]*)/
    SET_FOREGROUND       = /\A\e\[([\d;]*)m/

    def initialize(buffer)
      self.buffer = buffer
      self.stack = []
      self.queue = Queue.new
    end

    def use_pty
      Yonde.pty(queue, self)
    end

    def call(input)
      stack.concat(input.chars.to_a)
      term_input(stack, [])
    end

    def term_cmd(seq, md, *cmd)
      # p term_cmd: cmd
      md[0].size.times{ seq.shift }
      buffer.send(*cmd) unless cmd.empty?
      seq.empty?
    end

    def term_input(sequence, lost)
      sequence[0,0] = lost
      string = sequence.join

      case string
      when PARM_DCH
        return term_cmd(sequence, $~, :parm_dch, $1.to_i)
      when CHANGE_SCROLL_REGION
        return term_cmd(sequence, $~, :change_scroll_region, $1.to_i, $2.to_i)
      when COLUMN_ADDRESS
        return term_cmd(sequence, $~, :column_address, $1.to_i)
      when ROW_ADDRESS
        return term_cmd(sequence, $~, :row_address, $1.to_i)
      when SET_A_BACKGROUND
        return term_cmd(sequence, $~, :set_a_background, $1.to_i)
      when SET_A_FOREGROUND
        return term_cmd(sequence, $~, :set_a_foreground, $1.to_i)
      when SET_FOREGROUND
        args = *$1.split(';').map{|a| a.to_i }
        return term_cmd(sequence, $~, :wtf, *args) if args.empty?
        return term_cmd(sequence, $~, :set_foreground, *args)
      when ERASE_CHARS
        return term_cmd(sequence, $~, :erase_chars, $1.to_i)
      when INITIALIZE_COLOR
        return term_cmd(sequence, $~, :initialize_color, $1)
      when SET_BACKGROUND
        args = *$1.split(';').map{|a| a.to_i }
        return term_cmd(sequence, $~, :wtf, *args) if args.empty?
        return term_cmd(sequence, $~, :set_background, *args)
      when PARM_ICH
        return term_cmd(sequence, $~, :parm_ich, $1.to_i)
      when CURSOR_ADDRESS
        return term_cmd(sequence, $~, :cursor_address, $1.to_i, $2.to_i)
      when PARM_UP_CURSOR
        return term_cmd(sequence, $~, :parm_up_cursor, $1.to_i)
      when PARM_DOWN_CURSOR
        return term_cmd(sequence, $~, :parm_down_cursor, $1.to_i)
      when PARM_RIGHT_CURSOR
        return term_cmd(sequence, $~, :parm_right_cursor, $1.to_i)
      when PARM_LEFT_CURSOR
        return term_cmd(sequence, $~, :parm_left_cursor, $1.to_i)
      when CURSOR_HOME
        return term_cmd(sequence, $~, :cursor_home)
      when /\A\e\[>(\w)/
        return term_cmd(sequence, $~, :wtf, $1)
      else
        return false if sequence.first == "\e"

        while char = sequence.shift
          case char
          when "\e"
            sequence.unshift(char)
            return false
          when "\r"
            buffer.carriage_return
          when "\b"
            buffer.backspace
          when "\n"
            buffer.newline
          when "\a"
            @matrix[y][0..x].each do |cell|
              cell.configure(text: ' ')
            end
            self.x = 0
          when "\t", /[[:print:]]/
            buffer.write(char)
          else
            p fail: char
            sequence[0,0] = char
            return false # fail char.inspect
          end
        end
      end

      nil
    end
  end
end
