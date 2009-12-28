class Yonde
  class Buffer < Tk::Text

    attr_reader :x, :y

    def initialize(*args)
      super
      @y, @x = 1, 0

      @font = Tk::Font.new('Terminus 12')
      @font_width = @font.measure('0')
      @font_height = @font.metrics(:linespace)
      @background = '#000'
      @foreground = '#fff'

      width   = @font_height * 24
      height  = @font_width * 80
      options = {
        width:   width,
        height:  height,
        setgrid: true,
        wrap:    :char,
      }

      configure(options)
    end

    def empty?
      value == "\n"
    end

    def y=(y)
      @y = y.abs
    end

    def x=(x)
      @x = x.abs
    end

    def write(string)
      string.each_char do |char|
        replace("#{y}.#{x}", "#{y}.#{x + 1}", char)
        self.x += 1
      end
    end

    def backspace
      self.x -= 1
      replace("#{y}.#{x}", "#{y}.#{x + 1}", ' ')
    end

    def carriage_return
      self.x = 0
    end

    def newline
      self.y += 1
      insert("#{y}.#{x}", "\n")
    end

    def create_cells(y)
      @matrix[y] = matrix_y = []
      cell_y = @font_height + (@font_height * y)

      80.times do |x|
        cell_x = @font_width + (@font_width * x)
        matrix_y[x] = create_text(cell_x, cell_y)
      end

      matrix_y
    end

    def parm_dch(count)
      line = @matrix[y]

      line.each_with_index do |cell, idx|
        next if idx < x

        text =
          if replacement = line[x + idx]
            replacement.cget(:text)
          else
            ''
          end

        cell.configure(text: text)
      end
    end

    def erase_chars(count)
      @matrix[y][x,count].each{|cell| cell.configure(text: '') }
    end

    def wtf(*args)
    end

    def cursor_invisible
      @cursor_visible = false
    end

    def cursor_visible
      @cursor_visible = true
    end

    def to_status_line
      self.y = @matrix.size
    end

    def cursor_address(y, x)
      if compare("#{y}.#{x}", ">=", "#{y}.#{x} lineend")
        current = get("#{y}.0", "#{y}.0 lineend")
        replace("#{y}.0", "#{y}.0 lineend", current.ljust(x, " "))
      end

      self.x, self.y = x, y
    end

    def parm_up_cursor(count)
      self.y -= count
    end

    def parm_right_cursor(count)
      self.x += count
    end

    def parm_down_cursor(count)
      self.y += count
    end

    def parm_left_cursor(count)
      self.x -= count
    end

    def row_address(row)
      self.y = row
    end

    def column_address(column)
      self.x = column
    end

    A_STANDOUT   = 1
    A_UNDERLINE  = 2
    A_REVERSE    = 4
    A_BLINK      = 8
    A_DIM        = 16
    A_BOLD       = 32
    A_INVIS      = 64
    A_PROTECT    = 128
    A_ALTCHARSET = 256

    def enter_bold_mode
      @attribute = @attribute | A_BOLD
    end

    def enter_standout_mode
      @attribute = @attribute | A_STANDOUT
    end

    # start programs using cup
    def enter_ca_mode
    end

    # turn on automatic margins
    def enter_am_mode
    end

    def exit_standout_mode
    end

    def exit_underline_mode
    end

    def exit_insert_mode
    end

    COLORS = []
    def initialize_color(index, r, g, b)
      COLORS[index] = rgb_to_hex(r,g,b)
    end

    PAIRS = []
    def initialize_pair(index, fgr, fgg, fgb, bgr, bgg, bgb)
      PAIRS[index] = [rgb_to_hex(fgr, fgg, fgb), rgb_to_hex(bgr, bgg, bgb)]
    end

    def set_color_pair(index)
      @pair = PAIRS.fetch(index)
    end

    def change_scroll_region(*args)
    end

    def keypad_local
    end

    def key_up
      self.y -= 1
    end

    def clr_eos
      if line = @matrix[y]
        line.each_with_index do |cell, cell_x|
          cell.configure(text: ' ') if cell_x >= self.x
        end
      end

      if line = @matrix[(y+1)..-1]
        line.each do |cells|
          cells.each do |cell|
            cell.configure(text: ' ')
          end
        end
      end
    end

    def clr_eol
      @matrix[y][x..-1].each do |cell|
        cell.configure(text: ' ')
      end
    end

    def key_backspace
      write('0')
    end

    def cursor_home
      self.y, self.x = 0, 0
    end

    def clear_all_tabs
    end

    def clear_screen
      @matrix.each do |cells|
        cells.each do |cell|
          cell.configure(text: ' ')
        end
      end
      self.y, self.x = 0, 0
    end

    DARK_BLACK   = '#000000'
    DARK_RED     = '#cd0000'
    DARK_GREEN   = '#cd0000'
    DARK_YELLOW  = '#cdcd00'
    DARK_BLUE    = '#0000cd'
    DARK_MAGENTA = '#cd00cd'
    DARK_CYAN    = '#00cdcd'
    DARK_WHITE   = '#faebd7'

    BRIGHT_BLACK   = '#404040'
    BRIGHT_RED     = '#ff0000'
    BRIGHT_GREEN   = '#00ff00'
    BRIGHT_YELLOW  = '#ffff00'
    BRIGHT_BLUE    = '#0000ff'
    BRIGHT_MAGENTA = '#ff00ff'
    BRIGHT_CYAN    = '#00ffff'
    BRIGHT_WHITE   = '#ffffff'

    ANSI_COLORS = [
      [0x00, 0x00, 0x00],
      [0xcd, 0x00, 0x00],
      [0x00, 0xcd, 0x00],
      [0xcd, 0xcd, 0x00],
      [0x00, 0x00, 0xcd],
      [0xcd, 0x00, 0xcd],
      [0x00, 0xcd, 0xcd],
      [0xe5, 0xe5, 0xe5],
      [0x4d, 0x4d, 0x4d],
      [0xff, 0x00, 0x00],
      [0x00, 0xff, 0x00],
      [0xff, 0xff, 0x00],
      [0x00, 0x00, 0xff],
      [0xff, 0x00, 0xff],
      [0x00, 0xff, 0xff],
      [0xff, 0xff, 0xff],
    ]

    steps = [0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
    steps.each do |r|
      steps.each do |g|
        steps.each do |b|
          ANSI_COLORS << [r, g, b]
        end
      end
    end

    8.step 238, 10 do |n|
      ANSI_COLORS << [n, n, n]
    end

    ANSI_COLORS.map! do |rgb|
      '#' << rgb.map{|value| value.to_s(16).rjust(2, '0') }.join
    end

    ANSI_FOREGROUND = {}
    ANSI_FOREGROUND[ 0] = BRIGHT_WHITE
    ANSI_FOREGROUND[30] = BRIGHT_BLACK
    ANSI_FOREGROUND[31] = BRIGHT_RED
    ANSI_FOREGROUND[32] = BRIGHT_GREEN
    ANSI_FOREGROUND[33] = BRIGHT_YELLOW
    ANSI_FOREGROUND[34] = BRIGHT_BLUE
    ANSI_FOREGROUND[35] = BRIGHT_MAGENTA
    ANSI_FOREGROUND[36] = BRIGHT_CYAN
    ANSI_FOREGROUND[37] = BRIGHT_WHITE
    ANSI_FOREGROUND[39] = BRIGHT_WHITE

    def set_a_foreground(index)
      @foreground = ANSI_FOREGROUND.fetch(index)
    end

    ANSI_BACKGROUND = {}
    ANSI_BACKGROUND[40] = BRIGHT_BLACK
    ANSI_BACKGROUND[41] = BRIGHT_RED
    ANSI_FOREGROUND[42] = BRIGHT_GREEN
    ANSI_FOREGROUND[43] = BRIGHT_YELLOW
    ANSI_FOREGROUND[44] = BRIGHT_BLUE
    ANSI_FOREGROUND[45] = BRIGHT_MAGENTA
    ANSI_FOREGROUND[46] = BRIGHT_CYAN
    ANSI_FOREGROUND[47] = BRIGHT_WHITE
    ANSI_FOREGROUND[49] = BRIGHT_WHITE

    def set_a_background(index)
      @background = ANSI_BACKGROUND.fetch(index)
    end

    ANSI_ATTRIBUTE = {}

    def set_foreground(*indices)
      indices.each do |index|
        index = index.to_i

        if fg = ANSI_FOREGROUND[index]
          @foreground = fg
        elsif bg = ANSI_BACKGROUND[index]
          @background = bg
        elsif at = ANSI_ATTRIBUTE[index]
          @attribute = at
        else
          raise indices.inspect
        end
      end
    end

    def set_background(*indices)
      indices.each do |index|
        index = index.to_i

        if bg = ANSI_BACKGROUND[index]
          @background = bg
        elsif fg = ANSI_FOREGROUND[index]
          @foreground = fg
        elsif at = ANSI_ATTRIBUTE[index]
          @attribute = at
        else
          raise indices.inspect
        end
      end
    end

    def set_tab
    end

    # Shift to codeset 0 (EUC set 0, ASCII)
    def set0_des_seq
    end

    def reset_1string
    end

    def init_1string
    end

    # Set default pair to its original value
    def orig_pair
    end

    # enter 'keyboard_transmit' mode
    def keypad_xmit
    end
  end
end
