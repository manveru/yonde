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
  class Controller < Struct.new(:buffer, :queue, :term, :terminfo, :termbinds)
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
      self.termbinds = {}
      self.queue = Queue.new

      buffer.bind('<Key>'){|ev|    queue << ev.unicode; Tk.callback_break }
      buffer.bind('<Return>'){|ev| queue << ev.unicode; Tk.callback_break }
      buffer.bind('<Up>'){         queue << terminfo[:key_up]; Tk.callback_break }
      buffer.bind('<Down>'){       queue << terminfo[:key_down]; Tk.callback_break }
      buffer.bind('<Left>'){       queue << terminfo[:key_left]; Tk.callback_break }
      buffer.bind('<Right>'){      queue << terminfo[:key_right]; Tk.callback_break }
      buffer.focus
    end

    def destroy
      buffer.destroy
      Tk.exit
    end

    def use_pty
      Yonde.pty(queue, self)
    end

    def use_terminfo(term, terminfo)
      terminfo.each do |name, sequence|
        next if sequence =~ /%[^%]/ # uses parameter string
        bind(sequence, name)
      end

      case term
      when /rxvt|xterm/
        bind("\e[H\e[2J", :cursor_home)
        bind("\r", :carriage_return)
        bind("\b", :backspace)
        bind("\n", :newline)
      end

      self.term = term
      self.terminfo = terminfo
    end

    # called when outbuf changes
    def call(outbuf)
      begin
        size = outbuf.size
        try_execute(outbuf) && outbuf.replace('')
        return if outbuf.empty?
        new_size = outbuf.size
      end while size != new_size
    end

    def bind(sequence, action_name)
      return unless sequence.is_a?(String)
      return if sequence.empty?
      termbinds[sequence] = action_name.to_sym
    end

    def try_execute(outbuf)
      termbinds.each do |sequence, action|
        if outbuf.start_with?(sequence)
          p string: outbuf.slice!(0, sequence.size)
          p action: action
          puts
          buffer.send(action)
          return nil
        elsif sequence.start_with?(outbuf.slice(0, sequence.size))
          return nil
        end
      end

      term_input(outbuf)
    end

    def term_cmd(string, full, *cmd)
      p string: string.slice!(0, full.size)
      p action: cmd
      puts
      buffer.send(*cmd) unless cmd.empty?
      string.empty?
    end

    def term_input(string)
      case string
      when PARM_DCH
        term_cmd(string, $&, :parm_dch, $1.to_i)
      when CHANGE_SCROLL_REGION
        term_cmd(string, $&, :change_scroll_region, $1.to_i, $2.to_i)
      when COLUMN_ADDRESS
        term_cmd(string, $&, :column_address, $1.to_i)
      when ROW_ADDRESS
        term_cmd(string, $&, :row_address, $1.to_i)
      when SET_A_BACKGROUND
        term_cmd(string, $&, :set_a_background, $1.to_i)
      when SET_A_FOREGROUND
        term_cmd(string, $&, :set_a_foreground, $1.to_i)
      when SET_FOREGROUND
        args = *$1.split(';').map{|a| a.to_i }
        term_cmd(string, $&, :set_foreground, *args)
      when ERASE_CHARS
        term_cmd(string, $&, :erase_chars, $1.to_i)
      when INITIALIZE_COLOR
        args = *$1.split(';').map{|a| a.to_i }
        term_cmd(string, $&, :initialize_color, *args)
      when SET_BACKGROUND
        args = *$1.split(';').map{|a| a.to_i }
        term_cmd(string, $&, :set_background, *args)
      when PARM_ICH
        term_cmd(string, $&, :parm_ich, $1.to_i)
      when CURSOR_ADDRESS
        term_cmd(string, $&, :cursor_address, $1.to_i, $2.to_i)
      when PARM_UP_CURSOR
        term_cmd(string, $&, :parm_up_cursor, $1.to_i)
      when PARM_DOWN_CURSOR
        term_cmd(string, $&, :parm_down_cursor, $1.to_i)
      when PARM_RIGHT_CURSOR
        term_cmd(string, $&, :parm_right_cursor, $1.to_i)
      when PARM_LEFT_CURSOR
        term_cmd(string, $&, :parm_left_cursor, $1.to_i)
      when CURSOR_HOME
        term_cmd(string, $&, :cursor_home)
      when /\A\e/
        nil
      when /\A[[:print:]\t]+/
        term_cmd(string, $&, :write, $&)
      end
    end
  end
end
