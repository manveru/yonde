class Yonde
  class CachingFont < Struct.new(:font, :cache, :attributes)
    def initialize(attributes, cache = {})
      self.cache = cache
      self.attributes = attributes
      self.font = Tk::Font.new(attributes)
    end

    def new(attributes)
      self.class.new(attributes, cache)
    end

    def +(given)
      merged = attributes.merge(given)
      cache[merged] ||= self.class.new(merged, cache)
    end

    def to_s
      attributes.inspect.scan(/\w+/).join
    end

    def inspect
      attributes.inspect
    end

    def to_tcl
      font.to_tcl
    end
  end

  # Issues:
  #   * what the heck is correct scroll region behaviour?
  #   * need binding for ioctl to tell the world our real dimensions
  class Buffer < Tk::Text
    TAGS = {}
    FONTS = {}

    attr_accessor :controller
    attr_reader :x, :y, :background, :foreground

    def initialize(*args)
      super
      @y, @x = 1, 0

      base_font = Tk::Font.new('Terminus 9')
      @font = CachingFont.new(base_font.configure)
      font_width = base_font.measure('0')
      font_height = base_font.metrics(:linespace)
      self.background = '#000'
      self.foreground = '#fff'

      options = {
        background: '#000',
        borderwidth:  2,
        width:   80,
        height:  24,
        setgrid: true,
        wrap:    :char,
      }

      configure(options)
      clear_screen
    end

    def empty?
      value == "\n"
    end

    def adjust_insert
      mark_set(:insert, "#{y}.#{x}")
      see(:insert)
    end

    def update_tag
      @tag = "#{foreground}~#{background}~#@font"
      TAGS[@tag] ||= (
        tag_configure(@tag, foreground: foreground, background: background, font: @font)
        true
      )
    end

    def y=(y)
      @y = y >= 1 ? y : 1
    end

    def x=(x)
      @x = x >= 0 ? x : 0
    end

    def background=(bg)
      # p background: bg
      @background = bg
    end

    def foreground=(fg)
      # p foreground: fg
      @foreground = fg
    end

    def rgb_to_hex(r, g, b)
      '#' << [r, g, b].map{|n| n.to_s(16) }.join
    end

    def write(string)
      string.each_char do |char|
        replace("#{y}.#{x}", "#{y}.#{x + 1}", char, @tag)
        self.x += 1
      end
      adjust_insert
    end

    def backspace
      self.x -= 1
      replace("#{y}.#{x}", "#{y}.#{x + 1}", ' ')
      adjust_insert
    end

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

    ANSI_RESET = [0]

    A_STANDOUT   = 1
    A_UNDERLINE  = 2
    A_REVERSE    = 4
    A_BLINK      = 8
    A_DIM        = 16
    A_BOLD       = 32
    A_INVIS      = 64
    A_PROTECT    = 128
    A_ALTCHARSET = 256

    SET_COLORS = [
      '#000', '#00f', '#0f0', '#0ff', '#f00', '#f0f', '#ff0', '#fff',
    ]

    SET_A_COLORS = [
      '#000', '#f00', '#0f0', '#ff0', '#00f', '#f0f', '#0ff', '#fff',
      nil, '#fff',
    ]

    COLOR_PAIRS = []
    TABSTOPS = []

    # Following are all the methods corresponding to command sequences in
    # terminfo.
    # We should try to accumulate more information about what they are supposed
    # to do.
    # The manpage about terminfo is not always clear.

    # back tab (P)
    def back_tab
      Kernel.raise NotImplementedError
    end

    # audible signal (bell) (P)
    def bell
      Kernel.raise NotImplementedError
    end

    # carriage return (P*) (P*)
    def carriage_return
      self.x = 0
      adjust_insert
    end

    # Change number of characters per inch to #1
    def change_char_pitch
      Kernel.raise NotImplementedError
    end

    # Change number of lines per inch to #1
    def change_line_pitch
      Kernel.raise NotImplementedError
    end

    # Change horizontal resolution to #1
    def change_res_horz
      Kernel.raise NotImplementedError
    end

    # Change vertical resolution to #1
    def change_res_vert
      Kernel.raise NotImplementedError
    end

    # change region to line #1 to line #2 (P)
    def change_scroll_region(top, bottom)
      return if top > bottom
      @scroll_top, @scroll_bot = top, bottom
    end

    # like ip but when in insert mode
    def char_padding
      Kernel.raise NotImplementedError
    end

    # clear all tab stops (P)
    def clear_all_tabs
      TABSTOPS.clear
      configure(tabs: 8)
    end

    # clear right and left soft margins
    def clear_margins
      Kernel.raise NotImplementedError
    end

    # clear screen and home cursor (P*)
    def clear_screen
      replace('1.0', 'end', Array.new(24){ ' ' * 80 }.join("\n"))

      cursor_home
    end

    # Clear to beginning of line
    def clr_bol
      from, to = "#{y}.#{x} linestart", "#{y}.#{x}"
      replace(from, to, get(from, to).gsub(/./, ' '))
      adjust_insert
    end

    # clear to end of line (P)
    def clr_eol
      from, to = "#{y}.#{x}", "#{y}.#{x} lineend"
      replace(from, to, get(from, to).gsub(/./, ' '))
      adjust_insert
    end

    # clear to end of screen (P*)
    def clr_eos
      line = get("#{y}.#{x} linestart", "#{y}.#{x}")
      replace("#{y}.#{x} linestart", "#{y}.#{x} lineend", line[0, 80])
      (y + 1).upto(count('1.0', 'end', :lines)) do |y|
        replace("#{y}.0 linestart", "#{y}.0 lineend", ' ' * 80)
      end

      adjust_insert
    end

    # horizontal position #1, absolute (P)
    def column_address(column)
      self.x = column
      adjust_insert
    end

    # terminal settable cmd character in prototype !?
    def command_character
      Kernel.raise NotImplementedError
    end

    # define a window #1 from #2,#3 to #4,#5
    def create_window
      Kernel.raise NotImplementedError
    end

    # move to row #1 columns #2
    def cursor_address(y, x)
      if compare("#{y}.#{x}", ">=", "#{y}.#{x} lineend")
        current = get("#{y}.0", "#{y}.0 lineend")
        replace("#{y}.0", "#{y}.0 lineend", current.ljust(x, " ") + "\n")
      end

      self.y, self.x = y, x
      adjust_insert
    end

    # down one line
    def cursor_down
      Kernel.raise NotImplementedError
    end

    # home cursor (if no cup)
    def cursor_home
      self.y, self.x = 1, 0
      adjust_insert
    end

    # make cursor invisible
    def cursor_invisible
      configure insertbackground: '#000',
                insertborderwidth: 0
    end

    # move left one space
    def cursor_left
      Kernel.raise NotImplementedError
    end

    # memory relative cursor addressing, move to row #1 columns #2
    def cursor_mem_address
      Kernel.raise NotImplementedError
    end

    # make cursor appear normal (undo civis/cvvis)
    def cursor_normal
      configure insertbackground: '#ddd',
                insertborderwidth: 1
    end

    # non-destructive space (move right one space)
    def cursor_right
      Kernel.raise NotImplementedError
    end

    # last line, first column (if no cup)
    def cursor_to_ll
      Kernel.raise NotImplementedError
    end

    # up one line
    def cursor_up
      self.y -= 1
      adjust_insert
    end

    # make cursor very visible
    def cursor_visible
      configure insertbackground: '#ddd',
                insertborderwidth: 1
    end

    # Define a character #1, #2 dots wide, descender #3
    def define_char
      Kernel.raise NotImplementedError
    end

    # delete character (P*)
    def delete_character
      Kernel.raise NotImplementedError
    end

    # delete line (P*)
    def delete_line
      Kernel.raise NotImplementedError
    end

    # dial number #1
    def dial_phone
      Kernel.raise NotImplementedError
    end

    # disable status line
    def dis_status_line
      Kernel.raise NotImplementedError
    end

    # display clock
    def display_clock
      Kernel.raise NotImplementedError
    end

    # half a line down
    def down_half_line
      Kernel.raise NotImplementedError
    end

    # enable alternate char set
    def ena_acs
      # Kernel.raise NotImplementedError
    end

    # erase #1 characters (P)
    def erase_chars
      Kernel.raise NotImplementedError
    end

    # pause for 2-3 seconds
    def fixed_pause
      Kernel.raise NotImplementedError
    end

    # flash switch hook
    def flash_hook
      Kernel.raise NotImplementedError
    end

    # visible bell (may not move cursor)
    def flash_screen
      Kernel.raise NotImplementedError
    end

    # hardcopy terminal page eject (P*)
    def form_feed
      Kernel.raise NotImplementedError
    end

    # return from status line
    def from_status_line
      Kernel.raise NotImplementedError
    end

    # go to window #1
    def goto_window
      Kernel.raise NotImplementedError
    end

    # hang-up phone
    def hangup
      Kernel.raise NotImplementedError
    end

    # initialization string
    def init_1string
      Kernel.raise NotImplementedError
    end

    # initialization string
    def init_2string
      Kernel.raise NotImplementedError
    end

    # initialization string
    def init_3string
      Kernel.raise NotImplementedError
    end

    # name of initialization file
    def init_file
      Kernel.raise NotImplementedError
    end

    # path name of program for initialization
    def init_prog
      Kernel.raise NotImplementedError
    end

    # initialize color #1 to (#2,#3,#4)
    def initialize_color(name, r = nil, g = nil, b = nil)
    end

    # Initialize color pair #1 to fg=(#2,#3,#4), bg=(#5,#6,#7)
    def initialize_pair(name, fgr, fgg, fgb, bgr, bgg, bgb)
      COLOR_PAIRS[name] = [rgb_to_hex(fgr, fgg, fgb), rgb_to_hex(bgr, bgg, bgb)]
    end

    # insert character (P)
    def insert_character
      Kernel.raise NotImplementedError
    end

    # insert line (P*)
    def insert_line
      insert("#{y}.0 lineend", "\n")
    end

    # insert padding after inserted character
    def insert_padding
      Kernel.raise NotImplementedError
    end

    # upper left of keypad
    def key_a1
      Kernel.raise NotImplementedError
    end

    # upper right of keypad
    def key_a3
      Kernel.raise NotImplementedError
    end

    # center of keypad
    def key_b2
      Kernel.raise NotImplementedError
    end

    # backspace key
    # FIXME: this is what it _should_ do... find out why???
    def key_backspace
      write('0')
    end

    # begin key
    def key_beg
      Kernel.raise NotImplementedError
    end

    # back-tab key
    def key_btab
      Kernel.raise NotImplementedError
    end

    # lower left of keypad
    def key_c1
      Kernel.raise NotImplementedError
    end

    # lower right of keypad
    def key_c3
      Kernel.raise NotImplementedError
    end

    # cancel key
    def key_cancel
      Kernel.raise NotImplementedError
    end

    # clear-all-tabs key
    def key_catab
      Kernel.raise NotImplementedError
    end

    # clear-screen or erase key
    def key_clear
      Kernel.raise NotImplementedError
    end

    # close key
    def key_close
      Kernel.raise NotImplementedError
    end

    # command key
    def key_command
      Kernel.raise NotImplementedError
    end

    # copy key
    def key_copy
      Kernel.raise NotImplementedError
    end

    # create key
    def key_create
      Kernel.raise NotImplementedError
    end

    # clear-tab key
    def key_ctab
      Kernel.raise NotImplementedError
    end

    # delete-character key
    def key_dc
      Kernel.raise NotImplementedError
    end

    # delete-line key
    def key_dl
      Kernel.raise NotImplementedError
    end

    # down-arrow key
    def key_down
      Kernel.raise NotImplementedError
    end

    # sent by rmir or smir in insert mode
    def key_eic
      Kernel.raise NotImplementedError
    end

    # end key
    def key_end
      Kernel.raise NotImplementedError
    end

    # enter/send key
    def key_enter
      Kernel.raise NotImplementedError
    end

    # clear-to-end-of-line key
    def key_eol
      Kernel.raise NotImplementedError
    end

    # clear-to-end-of- screen key
    def key_eos
      Kernel.raise NotImplementedError
    end

    # exit key
    def key_exit
      Kernel.raise NotImplementedError
    end

    # F0 function key
    def key_f0
      Kernel.raise NotImplementedError
    end

    # F1 function key
    def key_f1
      Kernel.raise NotImplementedError
    end

    # F10 function key
    def key_f10
      Kernel.raise NotImplementedError
    end

    # F11 function key
    def key_f11
      Kernel.raise NotImplementedError
    end

    # F12 function key
    def key_f12
      Kernel.raise NotImplementedError
    end

    # F13 function key
    def key_f13
      Kernel.raise NotImplementedError
    end

    # F14 function key
    def key_f14
      Kernel.raise NotImplementedError
    end

    # F15 function key
    def key_f15
      Kernel.raise NotImplementedError
    end

    # F16 function key
    def key_f16
      Kernel.raise NotImplementedError
    end

    # F17 function key
    def key_f17
      Kernel.raise NotImplementedError
    end

    # F18 function key
    def key_f18
      Kernel.raise NotImplementedError
    end

    # F19 function key
    def key_f19
      Kernel.raise NotImplementedError
    end

    # F2 function key
    def key_f2
      Kernel.raise NotImplementedError
    end

    # F20 function key
    def key_f20
      Kernel.raise NotImplementedError
    end

    # F21 function key
    def key_f21
      Kernel.raise NotImplementedError
    end

    # F22 function key
    def key_f22
      Kernel.raise NotImplementedError
    end

    # F23 function key
    def key_f23
      Kernel.raise NotImplementedError
    end

    # F24 function key
    def key_f24
      Kernel.raise NotImplementedError
    end

    # F25 function key
    def key_f25
      Kernel.raise NotImplementedError
    end

    # F26 function key
    def key_f26
      Kernel.raise NotImplementedError
    end

    # F27 function key
    def key_f27
      Kernel.raise NotImplementedError
    end

    # F28 function key
    def key_f28
      Kernel.raise NotImplementedError
    end

    # F29 function key
    def key_f29
      Kernel.raise NotImplementedError
    end

    # F3 function key
    def key_f3
      Kernel.raise NotImplementedError
    end

    # F30 function key
    def key_f30
      Kernel.raise NotImplementedError
    end

    # F31 function key
    def key_f31
      Kernel.raise NotImplementedError
    end

    # F32 function key
    def key_f32
      Kernel.raise NotImplementedError
    end

    # F33 function key
    def key_f33
      Kernel.raise NotImplementedError
    end

    # F34 function key
    def key_f34
      Kernel.raise NotImplementedError
    end

    # F35 function key
    def key_f35
      Kernel.raise NotImplementedError
    end

    # F36 function key
    def key_f36
      Kernel.raise NotImplementedError
    end

    # F37 function key
    def key_f37
      Kernel.raise NotImplementedError
    end

    # F38 function key
    def key_f38
      Kernel.raise NotImplementedError
    end

    # F39 function key
    def key_f39
      Kernel.raise NotImplementedError
    end

    # F4 function key
    def key_f4
      Kernel.raise NotImplementedError
    end

    # F40 function key
    def key_f40
      Kernel.raise NotImplementedError
    end

    # F41 function key
    def key_f41
      Kernel.raise NotImplementedError
    end

    # F42 function key
    def key_f42
      Kernel.raise NotImplementedError
    end

    # F43 function key
    def key_f43
      Kernel.raise NotImplementedError
    end

    # F44 function key
    def key_f44
      Kernel.raise NotImplementedError
    end

    # F45 function key
    def key_f45
      Kernel.raise NotImplementedError
    end

    # F46 function key
    def key_f46
      Kernel.raise NotImplementedError
    end

    # F47 function key
    def key_f47
      Kernel.raise NotImplementedError
    end

    # F48 function key
    def key_f48
      Kernel.raise NotImplementedError
    end

    # F49 function key
    def key_f49
      Kernel.raise NotImplementedError
    end

    # F5 function key
    def key_f5
      Kernel.raise NotImplementedError
    end

    # F50 function key
    def key_f50
      Kernel.raise NotImplementedError
    end

    # F51 function key
    def key_f51
      Kernel.raise NotImplementedError
    end

    # F52 function key
    def key_f52
      Kernel.raise NotImplementedError
    end

    # F53 function key
    def key_f53
      Kernel.raise NotImplementedError
    end

    # F54 function key
    def key_f54
      Kernel.raise NotImplementedError
    end

    # F55 function key
    def key_f55
      Kernel.raise NotImplementedError
    end

    # F56 function key
    def key_f56
      Kernel.raise NotImplementedError
    end

    # F57 function key
    def key_f57
      Kernel.raise NotImplementedError
    end

    # F58 function key
    def key_f58
      Kernel.raise NotImplementedError
    end

    # F59 function key
    def key_f59
      Kernel.raise NotImplementedError
    end

    # F6 function key
    def key_f6
      Kernel.raise NotImplementedError
    end

    # F60 function key
    def key_f60
      Kernel.raise NotImplementedError
    end

    # F61 function key
    def key_f61
      Kernel.raise NotImplementedError
    end

    # F62 function key
    def key_f62
      Kernel.raise NotImplementedError
    end

    # F63 function key
    def key_f63
      Kernel.raise NotImplementedError
    end

    # F7 function key
    def key_f7
      Kernel.raise NotImplementedError
    end

    # F8 function key
    def key_f8
      Kernel.raise NotImplementedError
    end

    # F9 function key
    def key_f9
      Kernel.raise NotImplementedError
    end

    # find key
    def key_find
      Kernel.raise NotImplementedError
    end

    # help key
    def key_help
      Kernel.raise NotImplementedError
    end

    # home key
    def key_home
      Kernel.raise NotImplementedError
    end

    # insert-character key
    def key_ic
      Kernel.raise NotImplementedError
    end

    # insert-line key
    def key_il
      Kernel.raise NotImplementedError
    end

    # left-arrow key
    def key_left
      Kernel.raise NotImplementedError
    end

    # lower-left key (home down)
    def key_ll
      Kernel.raise NotImplementedError
    end

    # mark key
    def key_mark
      Kernel.raise NotImplementedError
    end

    # message key
    def key_message
      Kernel.raise NotImplementedError
    end

    # move key
    def key_move
      Kernel.raise NotImplementedError
    end

    # next key
    def key_next
      Kernel.raise NotImplementedError
    end

    # next-page key
    def key_npage
      Kernel.raise NotImplementedError
    end

    # open key
    def key_open
      Kernel.raise NotImplementedError
    end

    # options key
    def key_options
      Kernel.raise NotImplementedError
    end

    # previous-page key
    def key_ppage
      Kernel.raise NotImplementedError
    end

    # previous key
    def key_previous
      Kernel.raise NotImplementedError
    end

    # print key
    def key_print
      Kernel.raise NotImplementedError
    end

    # redo key
    def key_redo
      Kernel.raise NotImplementedError
    end

    # reference key
    def key_reference
      Kernel.raise NotImplementedError
    end

    # refresh key
    def key_refresh
      Kernel.raise NotImplementedError
    end

    # replace key
    def key_replace
      Kernel.raise NotImplementedError
    end

    # restart key
    def key_restart
      Kernel.raise NotImplementedError
    end

    # resume key
    def key_resume
      Kernel.raise NotImplementedError
    end

    # right-arrow key
    def key_right
      Kernel.raise NotImplementedError
    end

    # save key
    def key_save
      Kernel.raise NotImplementedError
    end

    # shifted begin key
    def key_sbeg
      Kernel.raise NotImplementedError
    end

    # shifted cancel key
    def key_scancel
      Kernel.raise NotImplementedError
    end

    # shifted command key
    def key_scommand
      Kernel.raise NotImplementedError
    end

    # shifted copy key
    def key_scopy
      Kernel.raise NotImplementedError
    end

    # shifted create key
    def key_screate
      Kernel.raise NotImplementedError
    end

    # shifted delete-character key
    def key_sdc
      Kernel.raise NotImplementedError
    end

    # shifted delete-line key
    def key_sdl
      Kernel.raise NotImplementedError
    end

    # select key
    def key_select
      Kernel.raise NotImplementedError
    end

    # shifted end key
    def key_send
      Kernel.raise NotImplementedError
    end

    # shifted clear-to- end-of-line key
    def key_seol
      Kernel.raise NotImplementedError
    end

    # shifted exit key
    def key_sexit
      Kernel.raise NotImplementedError
    end

    # scroll-forward key
    def key_sf
      Kernel.raise NotImplementedError
    end

    # shifted find key
    def key_sfind
      Kernel.raise NotImplementedError
    end

    # shifted help key
    def key_shelp
      Kernel.raise NotImplementedError
    end

    # shifted home key
    def key_shome
      Kernel.raise NotImplementedError
    end

    # shifted insert-character key
    def key_sic
      Kernel.raise NotImplementedError
    end

    # shifted left-arrow key
    def key_sleft
      Kernel.raise NotImplementedError
    end

    # shifted message key
    def key_smessage
      Kernel.raise NotImplementedError
    end

    # shifted move key
    def key_smove
      Kernel.raise NotImplementedError
    end

    # shifted next key
    def key_snext
      Kernel.raise NotImplementedError
    end

    # shifted options key
    def key_soptions
      Kernel.raise NotImplementedError
    end

    # shifted previous key
    def key_sprevious
      Kernel.raise NotImplementedError
    end

    # shifted print key
    def key_sprint
      Kernel.raise NotImplementedError
    end

    # scroll-backward key
    def key_sr
      Kernel.raise NotImplementedError
    end

    # shifted redo key
    def key_sredo
      Kernel.raise NotImplementedError
    end

    # shifted replace key
    def key_sreplace
      Kernel.raise NotImplementedError
    end

    # shifted right-arrow key
    def key_sright
      Kernel.raise NotImplementedError
    end

    # shifted resume key
    def key_srsume
      Kernel.raise NotImplementedError
    end

    # shifted save key
    def key_ssave
      Kernel.raise NotImplementedError
    end

    # shifted suspend key
    def key_ssuspend
      Kernel.raise NotImplementedError
    end

    # set-tab key
    def key_stab
      Kernel.raise NotImplementedError
    end

    # shifted undo key
    def key_sundo
      Kernel.raise NotImplementedError
    end

    # suspend key
    def key_suspend
      Kernel.raise NotImplementedError
    end

    # undo key
    def key_undo
      Kernel.raise NotImplementedError
    end

    # up-arrow key
    def key_up
      self.y -= 1
      adjust_insert
    end

    # leave 'keyboard_transmit' mode
    # means the keypad should be disabled
    def keypad_local
      controller.keypad = false
    end

    # enter 'keyboard_transmit' mode
    # means that the keypad should be enabled
    def keypad_xmit
      controller.keypad = true
    end

    # label on function key f0 if not f0
    def lab_f0
      Kernel.raise NotImplementedError
    end

    # label on function key f1 if not f1
    def lab_f1
      Kernel.raise NotImplementedError
    end

    # label on function key f10 if not f10
    def lab_f10
      Kernel.raise NotImplementedError
    end

    # label on function key f2 if not f2
    def lab_f2
      Kernel.raise NotImplementedError
    end

    # label on function key f3 if not f3
    def lab_f3
      Kernel.raise NotImplementedError
    end

    # label on function key f4 if not f4
    def lab_f4
      Kernel.raise NotImplementedError
    end

    # label on function key f5 if not f5
    def lab_f5
      Kernel.raise NotImplementedError
    end

    # label on function key f6 if not f6
    def lab_f6
      Kernel.raise NotImplementedError
    end

    # label on function key f7 if not f7
    def lab_f7
      Kernel.raise NotImplementedError
    end

    # label on function key f8 if not f8
    def lab_f8
      Kernel.raise NotImplementedError
    end

    # label on function key f9 if not f9
    def lab_f9
      Kernel.raise NotImplementedError
    end

    # label format
    def label_format
      Kernel.raise NotImplementedError
    end

    # turn off soft labels
    def label_off
      Kernel.raise NotImplementedError
    end

    # turn on soft labels
    def label_on
      Kernel.raise NotImplementedError
    end

    # turn off meta mode
    def meta_off
      Kernel.raise NotImplementedError
    end

    # turn on meta mode (8th-bit on)
    def meta_on
      Kernel.raise NotImplementedError
    end

    # Like column_address in micro mode
    def micro_column_address
      Kernel.raise NotImplementedError
    end

    # Like cursor_down in micro mode
    def micro_down
      Kernel.raise NotImplementedError
    end

    # Like cursor_left in micro mode
    def micro_left
      Kernel.raise NotImplementedError
    end

    # Like cursor_right in micro mode
    def micro_right
      Kernel.raise NotImplementedError
    end

    # Like row_address #1 in micro mode
    def micro_row_address
      Kernel.raise NotImplementedError
    end

    # Like cursor_up in micro mode
    def micro_up
      Kernel.raise NotImplementedError
    end

    # newline (behave like cr followed by lf)
    def newline
      self.x = 0
      self.y += 1
      adjust_insert
    end

    # Match software bits to print-head pins
    def order_of_pins
      Kernel.raise NotImplementedError
    end

    # Set all color pairs to the original ones
    def orig_colors
      Kernel.raise NotImplementedError
    end

    # Set default pair to its original value
    def orig_pair
      COLOR_PAIRS[0] = []
    end

    # padding char (instead of null)
    def pad_char
      Kernel.raise NotImplementedError
    end

    # delete #1 characters (P*)
    def parm_dch(count)
    end

    # delete #1 lines (P*)
    def parm_delete_line(count)
    end

    # down #1 lines (P*)
    def parm_down_cursor(count)
      self.y += count
      adjust_insert
    end

    # Like parm_down_cursor in micro mode
    def parm_down_micro
      Kernel.raise NotImplementedError
    end

    # insert #1 characters (P*)
    def parm_ich(count)
    end

    # scroll forward #1 lines (P)
    def parm_index(count)
    end

    # insert #1 lines (P*)
    def parm_insert_line(count)
    end

    # move #1 characters to the left (P)
    def parm_left_cursor(count)
      self.x -= count
      adjust_insert
    end

    # Like parm_left_cursor in micro mode
    def parm_left_micro
      Kernel.raise NotImplementedError
    end

    # move #1 characters to the right (P*)
    def parm_right_cursor(count)
      self.x += count
      adjust_insert
    end

    # Like parm_right_cursor in micro mode
    def parm_right_micro
      Kernel.raise NotImplementedError
    end

    # scroll back #1 lines (P)
    def parm_rindex
      Kernel.raise NotImplementedError
    end

    # up #1 lines (P*)
    def parm_up_cursor(count)
      self.y -= count
      adjust_insert
    end

    # Like parm_up_cursor in micro mode
    def parm_up_micro
      Kernel.raise NotImplementedError
    end

    # program function key #1 to type string #2
    def pkey_key
      Kernel.raise NotImplementedError
    end

    # program function key #1 to execute string #2
    def pkey_local
      Kernel.raise NotImplementedError
    end

    # program function key #1 to transmit string #2
    def pkey_xmit
      Kernel.raise NotImplementedError
    end

    # program label #1 to show string #2
    def plab_norm
      Kernel.raise NotImplementedError
    end

    # print contents of screen
    def print_screen
      Kernel.raise NotImplementedError
    end

    # turn on printer for #1 bytes
    def prtr_non
      Kernel.raise NotImplementedError
    end

    # turn off printer
    def prtr_off
      Kernel.raise NotImplementedError
    end

    # turn on printer
    def prtr_on
      Kernel.raise NotImplementedError
    end

    # select pulse dialing
    def pulse
      Kernel.raise NotImplementedError
    end

    # dial number #1 without checking
    def quick_dial
      Kernel.raise NotImplementedError
    end

    # remove clock
    def remove_clock
      Kernel.raise NotImplementedError
    end

    # repeat char #1 #2 times (P*)
    def repeat_char
      Kernel.raise NotImplementedError
    end

    # send next input char (for ptys)
    def req_for_input
      Kernel.raise NotImplementedError
    end

    # reset string
    def reset_1string
      # Kernel.raise NotImplementedError
    end

    # reset string
    def reset_2string
      # Kernel.raise NotImplementedError
    end

    # reset string
    def reset_3string
      # Kernel.raise NotImplementedError
    end

    # name of reset file
    def reset_file
      Kernel.raise NotImplementedError
    end

    # restore cursor to position of last save_cursor
    def restore_cursor
      Kernel.raise NotImplementedError
    end

    # vertical position #1 absolute (P)
    def row_address(row)
      self.y = row
      adjust_insert
    end

    # save current cursor position (P)
    def save_cursor
      Kernel.raise NotImplementedError
    end

    # scroll text up (P)
    def scroll_forward
      Kernel.raise NotImplementedError
    end

    # scroll text down (P)
    def scroll_reverse
      p top: @scroll_top, bot: @scroll_bot
      Kernel.raise NotImplementedError
    end

    # Select character set, #1
    def select_char_set
      Kernel.raise NotImplementedError
    end

    # define video attributes #1-#9 (PG9)
    def set_attributes(*args)
      args.each do |arg|
        case arg
        when 0 # reset
          self.background = '#000'
          self.foreground = '#fff'
          @font = (@font + {weight: :normal})
        when 1 # bold
          @font = (@font + {weight: :bold})
        else # color?
          set_ansi_color(arg)
        end
      end

      if args.empty?
        self.background = '#000'
        self.foreground = '#fff'
        @font = (@font + {weight: :normal})
      end

      update_tag
    end

    def set_ansi_color(raw)
      tenth, oneth = raw.divmod(10)

      if tenth == 3
        self.foreground = SET_A_COLORS.fetch(oneth)
      elsif tenth == 4
        self.background = SET_A_COLORS.fetch(oneth)
      else
        Kernel.raise ArgumentError, "set_ansi_color(%p)" % [raw]
      end
    rescue IndexError => ex
      warn ex.message
    end

    # Set background color #1
    def set_background(*colors)
      colors.each{|color|
        if color < 49
          set_ansi_color(color)
        else
          self.background = ANSI_COLORS.fetch(color)
        end
      }
      update_tag
    end

    # Set bottom margin at current line
    def set_bottom_margin
      Kernel.raise NotImplementedError
    end

    # Set bottom margin at line #1 or (if smgtp is not given) #2 lines from bottom
    def set_bottom_margin_parm
      Kernel.raise NotImplementedError
    end

    # set clock, #1 hrs #2 mins #3 secs
    def set_clock
      Kernel.raise NotImplementedError
    end

    # Set current color pair to #1
    def set_color_pair
      Kernel.raise NotImplementedError
    end

    # Set foreground color #1
    def set_foreground(*colors)
      colors.each{|color| set_ansi_color(color) }
      update_tag
    end

    # set left soft margin at current column. See smgl. (ML is not in BSD termcap).
    def set_left_margin
      Kernel.raise NotImplementedError
    end

    # Set left (right) margin at column #1
    def set_left_margin_parm
      Kernel.raise NotImplementedError
    end

    # set right soft margin at current column
    def set_right_margin
      Kernel.raise NotImplementedError
    end

    # Set right margin at column #1
    def set_right_margin_parm
      Kernel.raise NotImplementedError
    end

    # set a tab in every row, current columns
    def set_tab
      TABSTOPS << x
      TABSTOPS.sort!
      configure(tabs: TABSTOPS)
    end

    # Set top margin at current line
    def set_top_margin
      Kernel.raise NotImplementedError
    end

    # Set top (bottom) margin at row #1
    def set_top_margin_parm
      Kernel.raise NotImplementedError
    end

    # current window is lines #1-#2 cols #3-#4
    def set_window
      Kernel.raise NotImplementedError
    end

    # Start printing bit image graphics
    def start_bit_image
      Kernel.raise NotImplementedError
    end

    # Start character set definition #1, with #2 characters in the set
    def start_char_set_def
      Kernel.raise NotImplementedError
    end

    # Stop printing bit image graphics
    def stop_bit_image
      Kernel.raise NotImplementedError
    end

    # End definition of character set #1
    def stop_char_set_def
      Kernel.raise NotImplementedError
    end

    # List of subscriptable characters
    def subscript_characters
      Kernel.raise NotImplementedError
    end

    # List of superscriptable characters
    def superscript_characters
      Kernel.raise NotImplementedError
    end

    # tab to next 8-space hardware tab stop
    def tab
      Kernel.raise NotImplementedError
    end

    # Printing any of these characters causes CR
    def these_cause_cr
      Kernel.raise NotImplementedError
    end

    # move to status line, column #1
    def to_status_line
      self.y, self.x = 24, 1
    end

    # select touch tone dialing
    def tone
      Kernel.raise NotImplementedError
    end

    # underline char and move past it
    def underline_char
      Kernel.raise NotImplementedError
    end

    # half a line up
    def up_half_line
      Kernel.raise NotImplementedError
    end

    # User string #0
    def user0
      Kernel.raise NotImplementedError
    end

    # User string #1
    def user1
      Kernel.raise NotImplementedError
    end

    # User string #2
    def user2
      Kernel.raise NotImplementedError
    end

    # User string #3
    def user3
      Kernel.raise NotImplementedError
    end

    # User string #4
    def user4
      Kernel.raise NotImplementedError
    end

    # User string #5
    def user5
      Kernel.raise NotImplementedError
    end

    # User string #6
    def user6
      Kernel.raise NotImplementedError
    end

    # User string #7
    def user7
      Kernel.raise NotImplementedError
    end

    # User string #8
    def user8
      Kernel.raise NotImplementedError
    end

    # User string #9
    def user9
      Kernel.raise NotImplementedError
    end

    # wait for dial-tone
    def wait_tone
      Kernel.raise NotImplementedError
    end

    # XOFF character
    def xoff_character
      Kernel.raise NotImplementedError
    end

    # XON character
    def xon_character
      Kernel.raise NotImplementedError
    end

    # No motion for subsequent character
    def zero_motion
      Kernel.raise NotImplementedError
    end

    # Alternate escape for scancode emulation
    def alt_scancode_esc
      Kernel.raise NotImplementedError
    end

    # Move to beginning of same row
    def bit_image_carriage_return
      Kernel.raise NotImplementedError
    end

    # Move to next row of the bit image
    def bit_image_newline
      Kernel.raise NotImplementedError
    end

    # Repeat bit image cell #1 #2 times
    def bit_image_repeat
      Kernel.raise NotImplementedError
    end

    # Produce #1'th item from list of character set names
    def char_set_names
      Kernel.raise NotImplementedError
    end

    # Init sequence for multiple codesets
    def code_set_init
      Kernel.raise NotImplementedError
    end

    # Give name for color #1
    def color_names
      Kernel.raise NotImplementedError
    end

    # Define rectangualar bit image region
    def define_bit_image_region
      Kernel.raise NotImplementedError
    end

    # Indicate language/codeset support
    def device_type
      Kernel.raise NotImplementedError
    end

    # Display PC character #1
    def display_pc_char
      Kernel.raise NotImplementedError
    end

    # End a bit-image region
    def end_bit_image_region
      Kernel.raise NotImplementedError
    end

    # Enter PC character display mode
    def enter_pc_charset_mode
      Kernel.raise NotImplementedError
    end

    # Enter PC scancode mode
    def enter_scancode_mode
      Kernel.raise NotImplementedError
    end

    # Exit PC character display mode
    def exit_pc_charset_mode
      Kernel.raise NotImplementedError
    end

    # Exit PC scancode mode
    def exit_scancode_mode
      Kernel.raise NotImplementedError
    end

    # Curses should get button events, parameter #1 not documented.
    def get_mouse
      Kernel.raise NotImplementedError
    end

    # Mouse event has occurred
    def key_mouse
      Kernel.raise NotImplementedError
    end

    # Mouse status information
    def mouse_info
      Kernel.raise NotImplementedError
    end

    # PC terminal options
    def pc_term_options
      Kernel.raise NotImplementedError
    end

    # Program function key #1 to type string #2 and show string #3
    def pkey_plab
      Kernel.raise NotImplementedError
    end

    # Request mouse position
    def req_mouse_pos
      Kernel.raise NotImplementedError
    end

    # Escape for scancode emulation
    def scancode_escape
      Kernel.raise NotImplementedError
    end

    # Shift to codeset 0 (EUC set 0, ASCII)
    def set0_des_seq
      Kernel.raise NotImplementedError
    end

    # Shift to codeset 1
    def set1_des_seq
      Kernel.raise NotImplementedError
    end

    # Shift to codeset 2
    def set2_des_seq
      Kernel.raise NotImplementedError
    end

    # Shift to codeset 3
    def set3_des_seq
      Kernel.raise NotImplementedError
    end

    # Set background color to #1, using ANSI escape
    def set_a_background(name)
      if name < 8
        self.background = SET_A_COLORS.fetch(name)
      else
        self.background = ANSI_COLORS.fetch(name)
      end

      update_tag
    end

    # Set foreground color to #1, using ANSI escape
    def set_a_foreground(name)
      if name < 8
        self.foreground = SET_A_COLORS.fetch(name)
      else
        self.foreground = ANSI_COLORS.fetch(name)
      end

      update_tag
    end

    # Change to ribbon color #1
    def set_color_band
      Kernel.raise NotImplementedError
    end

    # Set both left and right margins to #1, #2. (ML is not in BSD termcap).
    def set_lr_margin
      Kernel.raise NotImplementedError
    end

    # Set page length to #1 lines
    def set_page_length
      Kernel.raise NotImplementedError
    end

    # Sets both top and bottom margins to #1, #2
    def set_tb_margin
      Kernel.raise NotImplementedError
    end

    # Enter horizontal highlight mode
    def enter_horizontal_hl_mode
      Kernel.raise NotImplementedError
    end

    # Enter left highlight mode
    def enter_left_hl_mode
      Kernel.raise NotImplementedError
    end

    # Enter low highlight mode
    def enter_low_hl_mode
      Kernel.raise NotImplementedError
    end

    # Enter right highlight mode
    def enter_right_hl_mode
      Kernel.raise NotImplementedError
    end

    # Enter top highlight mode
    def enter_top_hl_mode
      Kernel.raise NotImplementedError
    end

    # Enter vertical highlight mode
    def enter_vertical_hl_mode
      Kernel.raise NotImplementedError
    end

    # Define second set of video attributes #1-#6
    def set_a_attributes
      Kernel.raise NotImplementedError
    end

    # YI Set page length to #1 hundredth of an inch
    def set_pglen_inch
      Kernel.raise NotImplementedError
    end

    # start alternate character set (P)
    def enter_alt_charset_mode
      Kernel.raise NotImplementedError
    end

    # turn on automatic margins
    def enter_am_mode
      @am_mode = true
    end

    # turn on blinking
    def enter_blink_mode
      Kernel.raise NotImplementedError
    end

    # turn on bold (extra bright) mode
    def enter_bold_mode
      @font = (@font + {weight: :bold})
    end

    # start programs using cup
    def enter_ca_mode
      clear_screen
    end

    # enter delete mode
    def enter_delete_mode
      Kernel.raise NotImplementedError
    end

    # turn on half-bright mode
    def enter_dim_mode
      Kernel.raise NotImplementedError
    end

    # Enter double-wide mode
    def enter_doublewide_mode
      Kernel.raise NotImplementedError
    end

    # Enter draft-quality mode
    def enter_draft_quality
      Kernel.raise NotImplementedError
    end

    # enter insert mode
    def enter_insert_mode
      Kernel.raise NotImplementedError
    end

    # Enter italic mode
    def enter_italics_mode
      Kernel.raise NotImplementedError
    end

    # Start leftward carriage motion
    def enter_leftward_mode
      Kernel.raise NotImplementedError
    end

    # Start micro-motion mode
    def enter_micro_mode
      Kernel.raise NotImplementedError
    end

    # Enter NLQ mode
    def enter_near_letter_quality
      Kernel.raise NotImplementedError
    end

    # Enter normal-quality mode
    def enter_normal_quality
      Kernel.raise NotImplementedError
    end

    # turn on protected mode
    def enter_protected_mode
      Kernel.raise NotImplementedError
    end

    # turn on reverse video mode
    def enter_reverse_mode
      self.foreground, self.background = self.background, self.foreground
    end

    # turn on blank mode (characters invisible)
    def enter_secure_mode
      Kernel.raise NotImplementedError
    end

    # Enter shadow-print mode
    def enter_shadow_mode
      Kernel.raise NotImplementedError
    end

    # begin standout mode
    # for rxvt this means blinking
    def enter_standout_mode
      # Kernel.raise NotImplementedError
    end

    # Enter subscript mode
    def enter_subscript_mode
      Kernel.raise NotImplementedError
    end

    # Enter superscript mode
    def enter_superscript_mode
      Kernel.raise NotImplementedError
    end

    # begin underline mode
    def enter_underline_mode
      Kernel.raise NotImplementedError
    end

    # Start upward carriage motion
    def enter_upward_mode
      Kernel.raise NotImplementedError
    end

    # turn on xon/xoff handshaking
    def enter_xon_mode
      Kernel.raise NotImplementedError
    end

    # end alternate character set (P)
    def exit_alt_charset_mode
      @alt_charset_mode = false
    end

    # turn off automatic margins
    def exit_am_mode
      Kernel.raise NotImplementedError
    end

    # turn off all attributes
    def exit_attribute_mode
      @font += {weight: :normal}
    end

    # end programs using cup
    def exit_ca_mode
      delete(1.0, :end)
      self.x, self.y = 0, 1
      adjust_insert
    end

    # end delete mode
    def exit_delete_mode
      Kernel.raise NotImplementedError
    end

    # End double-wide mode
    def exit_doublewide_mode
      Kernel.raise NotImplementedError
    end

    # exit insert mode
    def exit_insert_mode
      @insert_mode = false
    end

    # End italic mode
    def exit_italics_mode
      Kernel.raise NotImplementedError
    end

    # End left-motion mode
    def exit_leftward_mode
      Kernel.raise NotImplementedError
    end

    # End micro-motion mode
    def exit_micro_mode
      Kernel.raise NotImplementedError
    end

    # End shadow-print mode
    def exit_shadow_mode
      Kernel.raise NotImplementedError
    end

    # exit standout mode
    def exit_standout_mode
      # Kernel.raise NotImplementedError
    end

    # End subscript mode
    def exit_subscript_mode
      Kernel.raise NotImplementedError
    end

    # End superscript mode
    def exit_superscript_mode
      Kernel.raise NotImplementedError
    end

    # exit underline mode
    def exit_underline_mode
      @font += {underline: false}
    end

    # End reverse character motion
    def exit_upward_mode
      Kernel.raise NotImplementedError
    end

    # turn off xon/xoff
    def exit_xon_mode
      Kernel.raise NotImplementedError
    end

  end
end
