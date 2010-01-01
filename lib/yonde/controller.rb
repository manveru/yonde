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
  class Controller < Struct.new(:buffer, :queue, :term, :terminfo, :termbinds, :keypad)
    CHANGE_SCROLL_REGION = /\A\e\[(\d+);(\d+)r/
    COLUMN_ADDRESS       = /\A\e\[(\d+)G/
    CURSOR_ADDRESS       = /\A\e\[(\d+);(\d+)H/
    CURSOR_HOME          = /\A\e\[H/
    ERASE_CHARS          = /\A\e\[(\d+)X/
    INITIALIZE_COLOR     = /\A\e\]([\d;]*)[m;]/
    PARM_DCH             = /\A\e\[(\d+)P/
    PARM_DOWN_CURSOR     = /\A\e\[(\d+)B/
    PARM_ICH             = /\A\e\[(\d+)@/
    PARM_LEFT_CURSOR     = /\A\e\[(\d+)D/
    PARM_RIGHT_CURSOR    = /\A\e\[(\d+)C/
    PARM_UP_CURSOR       = /\A\e\[(\d+)A/
    ROW_ADDRESS          = /\A\e\[(\d+)d/
    SET_ATTRIBUTES       = /\A\e\[(0[;\d]*|)m/
    SET_A_BACKGROUND     = /\A\e\[48;5;([;\d]+)m/
    SET_A_FOREGROUND     = /\A\e\[38;5;([;\d]+)m/
    SET_BACKGROUND       = /\A\e\[(4[0-9][;\d]*|[^3][;\d]*)m/
    SET_FOREGROUND       = /\A\e\[(3[0-9][;\d]*)m/

    def initialize(buffer)
      self.buffer = buffer
      self.termbinds = {}
      self.queue = Queue.new
      self.keypad = false

      buffer.controller = self

      key('Key'){|event|    queue << event.unicode }
      key('Return'){|event| queue << event.unicode }
      key('Up'){            queue << terminfo[:key_up] }
      key('Down'){          queue << terminfo[:key_down] }
      key('Left'){          queue << terminfo[:key_left] }
      key('Right'){         queue << terminfo[:key_right] }

      key('KP_Begin'){|event|  queue << keypad ? event.unicode : terminfo[:key_beg] }
      key('KP_Delete'){|event| queue << keypad ? event.unicode : terminfo[:key_dc] }
      key('KP_Down'){|event|   queue << keypad ? event.unicode : terminfo[:key_down] }
      key('KP_End'){|event|    queue << keypad ? event.unicode : terminfo[:key_end] }
      key('KP_Enter'){|event|  queue << keypad ? event.unicode : terminfo[:key_enter] }
      key('KP_Home'){|event|   queue << keypad ? event.unicode : terminfo[:key_home] }
      key('KP_Left'){|event|   queue << keypad ? event.unicode : terminfo[:key_left] }
      key('KP_Next'){|event|   queue << keypad ? event.unicode : terminfo[:key_npage] }
      key('KP_Prior'){|event|  queue << keypad ? event.unicode : terminfo[:key_ppage] }
      key('KP_Right'){|event|  queue << keypad ? event.unicode : terminfo[:key_right] }
      key('KP_Up'){|event|     queue << keypad ? event.unicode : terminfo[:key_up] }

      # key('KP_Add'){|event|      queue << keypad ? event.unicode : terminfo[] }
      # key('KP_Subtract'){|event| queue << keypad ? event.unicode : terminfo[] }
      # key('KP_Multiply'){|event| queue << keypad ? event.unicode : terminfo[] }
      # key('KP_Divide'){|event|   queue << keypad ? event.unicode : terminfo[] }
      # key('KP_Insert'){|event|   queue << keypad ? event.unicode : terminfo[] }

      key('Num_Lock'){|event|
        if event.state == "0"
          @numlock = true
        else
          @numlock = false
        end
      }

      buffer.focus
    end

    def key(sequence, &block)
      buffer.bind("<#{sequence}>") do |event|
        # p event
        yield(event)
        Tk.callback_break
      end
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
      when /rxvt|xterm|screen/
        bind("\e[H\e[2J", :cursor_home)
        bind("\r", :carriage_return)
        bind("\b", :backspace)
        bind("\n", :newline)
        bind("\a", :clr_bol)
      end

      self.term = term
      self.terminfo = terminfo
    end

    # called when outbuf changes
    def call(outbuf)
      begin
        size = outbuf.size
        # puts
        # p before: outbuf
        try_execute(outbuf)
        # p after: outbuf
        new_size = outbuf.size
        if new_size == size
          warn "missing: #{outbuf.inspect}"
        end
      end until new_size == 0 || size == new_size
    end

    def bind(sequence, action_name)
      return unless sequence.is_a?(String)
      return if sequence.empty?
      termbinds[sequence] = action_name.to_sym
    end

    def try_execute(outbuf)
      termbinds.each do |sequence, action|
        if outbuf.start_with?(sequence)
          outbuf.slice!(0, sequence.size)
          p action
          buffer.send(action)
          return nil
        elsif sequence.start_with?(outbuf.slice(0, sequence.size))
          return nil
        end
      end

      term_input(outbuf)
    end

    def term_input(string)
      case string
      when /\A\e/
        case string
        when CHANGE_SCROLL_REGION
          p change_scroll_region: [$&, $1, $2]
          string.slice!(0, $&.size)
          buffer.change_scroll_region($1.to_i, $2.to_i)
        when COLUMN_ADDRESS
          p column_address: [$&, $1]
          string.slice!(0, $&.size)
          buffer.column_address($1.to_i)
        when CURSOR_ADDRESS
          p cursor_address: [$&, $1, $2]
          string.slice!(0, $&.size)
          buffer.cursor_address($1.to_i, $2.to_i)
        when CURSOR_HOME
          p cursor_home: [$&, $1]
          string.slice!(0, $&.size)
          buffer.cursor_home
        when ERASE_CHARS
          p erase_chars: [$&, $1]
          string.slice!(0, $&.size)
          buffer.erase_chars($1.to_i)
        when INITIALIZE_COLOR
          p initialize_color: [$&, $1]
          string.slice!(0, $&.size)
          args = $1.split(';').map{|a| a.to_i }
          buffer.initialize_color(*args)
        when PARM_DCH
          p parm_dch: [$&, $1]
          string.slice!(0, $&.size)
          buffer.parm_dch($1.to_i)
        when PARM_DOWN_CURSOR
          p parm_down_cursor: [$&, $1]
          string.slice!(0, $&.size)
          buffer.parm_down_cursor($1.to_i)
        when PARM_ICH
          p parm_ich: [$&, $1]
          string.slice!(0, $&.size)
          buffer.parm_ich($1.to_i)
        when PARM_LEFT_CURSOR
          p parm_left_cursor: [$&, $1]
          string.slice!(0, $&.size)
          buffer.parm_left_cursor($1.to_i)
        when PARM_RIGHT_CURSOR
          p parm_right_cursor: [$&, $1]
          string.slice!(0, $&.size)
          buffer.parm_right_cursor($1.to_i)
        when PARM_UP_CURSOR
          p parm_up_cursor: [$&, $1]
          string.slice!(0, $&.size)
          buffer.parm_up_cursor($1.to_i)
        when ROW_ADDRESS
          p row_address: [$&, $1]
          string.slice!(0, $&.size)
          buffer.row_address($1.to_i)
        when SET_A_BACKGROUND
          string.slice!(0, $&.size)
          args = $1.split(';').map{|a| a.to_i }
          # p set_a_background: [$&, *args]
          buffer.set_a_background(*args)
        when SET_A_FOREGROUND
          string.slice!(0, $&.size)
          args = $1.split(';').map{|a| a.to_i }
          # p set_a_foreground: [$&, *args]
          buffer.set_a_foreground(*args)
        when SET_ATTRIBUTES
          string.slice!(0, $&.size)
          args = $1.split(';').map{|a| a.to_i }
          # p set_attributes: [$&, *args]
          buffer.set_attributes(*args)
        when SET_BACKGROUND
          string.slice!(0, $&.size)
          args = $1.split(';').map{|a| a.to_i }
          # p set_background: [$&, *args]
          buffer.set_background(*args)
        when SET_FOREGROUND
          string.slice!(0, $&.size)
          args = $1.split(';').map{|a| a.to_i }
          # p set_foreground: [$&, *args]
          buffer.set_foreground(*args)
        when /\A\ek(.+)\e\\/
          string.slice!(0, $&.size)
          $0 = $1
        else
          return nil
        end
      when /\A\x0f/
        string.slice!(0, $&.size)
      when /\A[[:print:]\t]+/
        p write: $&
        string.slice!(0, $&.size)
        buffer.write($&)
      end
    end
  end
end
