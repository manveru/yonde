class Yonde
  class Buffer < Tk::Text
    TAGS = {}

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

    def adjust_insert
      mark_set(:insert, "#{y}.#{x}")
      see(:insert)
    end

    def update_tag
      @tag = "#@foreground~#@background~#@attribute"
      TAGS[@tag] ||= (
        tag_configure(@tag, foreground: @foreground, background: @background)
        true
      )
    end

    def y=(y)
      @y = y.abs
    end

    def x=(x)
      @x = x.abs
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

    def newline

    end

    def wtf(*args)
      # Kernel.raise NotImplementedError
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

    TERM_COLORS = {}
    TERM_COLORS[30] = BRIGHT_BLACK
    TERM_COLORS[31] = BRIGHT_RED
    TERM_COLORS[32] = BRIGHT_GREEN
    TERM_COLORS[33] = BRIGHT_YELLOW
    TERM_COLORS[34] = BRIGHT_BLUE
    TERM_COLORS[35] = BRIGHT_MAGENTA
    TERM_COLORS[36] = BRIGHT_CYAN
    TERM_COLORS[37] = BRIGHT_WHITE
    TERM_COLORS[40] = BRIGHT_BLACK
    TERM_COLORS[41] = BRIGHT_RED
    TERM_COLORS[42] = BRIGHT_GREEN
    TERM_COLORS[43] = BRIGHT_YELLOW
    TERM_COLORS[44] = BRIGHT_BLUE
    TERM_COLORS[45] = BRIGHT_MAGENTA
    TERM_COLORS[46] = BRIGHT_CYAN
    TERM_COLORS[47] = BRIGHT_WHITE

    TERM_ATTRIBUTES = {}
    TERM_ATTRIBUTES[1] = A_BOLD
    TERM_ATTRIBUTES[7] = A_REVERSE

    # Following are all the methods corresponding to command sequences in
    # terminfo.
    # We should try to accumulate more information about what they are supposed
    # to do.
    # The manpage about terminfo is not always clear.

    # back tab (P)
    def back_tab
    end

    # audible signal (bell) (P)
    def bell
    end

    # carriage return (P*) (P*)
    def carriage_return
      self.x = 0
      adjust_insert
    end

    # Change number of characters per inch to #1
    def change_char_pitch
    end

    # Change number of lines per inch to #1
    def change_line_pitch
    end

    # Change horizontal resolution to #1
    def change_res_horz
    end

    # Change vertical resolution to #1
    def change_res_vert
    end

    # change region to line #1 to line #2 (P)
    def change_scroll_region(from, to)
    end

    # like ip but when in insert mode
    def char_padding
    end

    # clear all tab stops (P)
    def clear_all_tabs
    end

    # clear right and left soft margins
    def clear_margins
    end

    # clear screen and home cursor (P*)
    def clear_screen
    end

    # Clear to beginning of line
    def clr_bol
    end

    # clear to end of line (P)
    def clr_eol
      replace("#{y}.#{x}", "#{y}.#{x} lineend", get("#{y}.#{x}", "#{y}.#{x} lineend").gsub(/./, ' '))
      adjust_insert
    end

    # clear to end of screen (P*)
    def clr_eos
      replace("#{y}.#{x}", 'end', get("#{y}.#{x}", "end").gsub(/./, ' '))
      adjust_insert
    end

    # horizontal position #1, absolute (P)
    def column_address(column)
      self.x = column
      adjust_insert
    end

    # terminal settable cmd character in prototype !?
    def command_character
    end

    # define a window #1 from #2,#3 to #4,#5
    def create_window
    end

    # move to row #1 columns #2
    def cursor_address(y, x)
      if compare("#{y}.#{x}", ">=", "#{y}.#{x} lineend")
        current = get("#{y}.0", "#{y}.0 lineend")
        replace("#{y}.0", "#{y}.0 lineend", current.ljust(x, " ") + "\n")
      end

      self.x, self.y = x, y
      adjust_insert
    end

    # down one line
    def cursor_down
    end

    # home cursor (if no cup)
    def cursor_home
      self.y, self.x = 0, 0
    end

    # make cursor invisible
    def cursor_invisible
      configure insertbackground: '#000',
                insertborderwidth: 0
    end

    # move left one space
    def cursor_left
    end

    # memory relative cursor addressing, move to row #1 columns #2
    def cursor_mem_address
    end

    # make cursor appear normal (undo civis/cvvis)
    def cursor_normal
      configure insertbackground: '#ddd',
                insertborderwidth: 1
    end

    # non-destructive space (move right one space)
    def cursor_right
    end

    # last line, first column (if no cup)
    def cursor_to_ll
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
    end

    # delete character (P*)
    def delete_character
    end

    # delete line (P*)
    def delete_line
    end

    # dial number #1
    def dial_phone
    end

    # disable status line
    def dis_status_line
    end

    # display clock
    def display_clock
    end

    # half a line down
    def down_half_line
    end

    # enable alternate char set
    def ena_acs
    end

    # erase #1 characters (P)
    def erase_chars
    end

    # pause for 2-3 seconds
    def fixed_pause
    end

    # flash switch hook
    def flash_hook
    end

    # visible bell (may not move cursor)
    def flash_screen
    end

    # hardcopy terminal page eject (P*)
    def form_feed
    end

    # return from status line
    def from_status_line
    end

    # go to window #1
    def goto_window
    end

    # hang-up phone
    def hangup
    end

    # initialization string
    def init_1string
    end

    # initialization string
    def init_2string
    end

    # initialization string
    def init_3string
    end

    # name of initialization file
    def init_file
    end

    # path name of program for initialization
    def init_prog
    end

    # initialize color #1 to (#2,#3,#4)
    def initialize_color(name, r = nil, g = nil, b = nil)
    end

    # Initialize color pair #1 to fg=(#2,#3,#4), bg=(#5,#6,#7)
    def initialize_pair
    end

    # insert character (P)
    def insert_character
    end

    # insert line (P*)
    def insert_line
    end

    # insert padding after inserted character
    def insert_padding
    end

    # upper left of keypad
    def key_a1
    end

    # upper right of keypad
    def key_a3
    end

    # center of keypad
    def key_b2
    end

    # backspace key
    # FIXME: this is what it _should_ do... find out why???
    def key_backspace
      write('0')
    end

    # begin key
    def key_beg
    end

    # back-tab key
    def key_btab
    end

    # lower left of keypad
    def key_c1
    end

    # lower right of keypad
    def key_c3
    end

    # cancel key
    def key_cancel
    end

    # clear-all-tabs key
    def key_catab
    end

    # clear-screen or erase key
    def key_clear
    end

    # close key
    def key_close
    end

    # command key
    def key_command
    end

    # copy key
    def key_copy
    end

    # create key
    def key_create
    end

    # clear-tab key
    def key_ctab
    end

    # delete-character key
    def key_dc
    end

    # delete-line key
    def key_dl
    end

    # down-arrow key
    def key_down
    end

    # sent by rmir or smir in insert mode
    def key_eic
    end

    # end key
    def key_end
    end

    # enter/send key
    def key_enter
    end

    # clear-to-end-of-line key
    def key_eol
    end

    # clear-to-end-of- screen key
    def key_eos
    end

    # exit key
    def key_exit
    end

    # F0 function key
    def key_f0
    end

    # F1 function key
    def key_f1
    end

    # F10 function key
    def key_f10
    end

    # F11 function key
    def key_f11
    end

    # F12 function key
    def key_f12
    end

    # F13 function key
    def key_f13
    end

    # F14 function key
    def key_f14
    end

    # F15 function key
    def key_f15
    end

    # F16 function key
    def key_f16
    end

    # F17 function key
    def key_f17
    end

    # F18 function key
    def key_f18
    end

    # F19 function key
    def key_f19
    end

    # F2 function key
    def key_f2
    end

    # F20 function key
    def key_f20
    end

    # F21 function key
    def key_f21
    end

    # F22 function key
    def key_f22
    end

    # F23 function key
    def key_f23
    end

    # F24 function key
    def key_f24
    end

    # F25 function key
    def key_f25
    end

    # F26 function key
    def key_f26
    end

    # F27 function key
    def key_f27
    end

    # F28 function key
    def key_f28
    end

    # F29 function key
    def key_f29
    end

    # F3 function key
    def key_f3
    end

    # F30 function key
    def key_f30
    end

    # F31 function key
    def key_f31
    end

    # F32 function key
    def key_f32
    end

    # F33 function key
    def key_f33
    end

    # F34 function key
    def key_f34
    end

    # F35 function key
    def key_f35
    end

    # F36 function key
    def key_f36
    end

    # F37 function key
    def key_f37
    end

    # F38 function key
    def key_f38
    end

    # F39 function key
    def key_f39
    end

    # F4 function key
    def key_f4
    end

    # F40 function key
    def key_f40
    end

    # F41 function key
    def key_f41
    end

    # F42 function key
    def key_f42
    end

    # F43 function key
    def key_f43
    end

    # F44 function key
    def key_f44
    end

    # F45 function key
    def key_f45
    end

    # F46 function key
    def key_f46
    end

    # F47 function key
    def key_f47
    end

    # F48 function key
    def key_f48
    end

    # F49 function key
    def key_f49
    end

    # F5 function key
    def key_f5
    end

    # F50 function key
    def key_f50
    end

    # F51 function key
    def key_f51
    end

    # F52 function key
    def key_f52
    end

    # F53 function key
    def key_f53
    end

    # F54 function key
    def key_f54
    end

    # F55 function key
    def key_f55
    end

    # F56 function key
    def key_f56
    end

    # F57 function key
    def key_f57
    end

    # F58 function key
    def key_f58
    end

    # F59 function key
    def key_f59
    end

    # F6 function key
    def key_f6
    end

    # F60 function key
    def key_f60
    end

    # F61 function key
    def key_f61
    end

    # F62 function key
    def key_f62
    end

    # F63 function key
    def key_f63
    end

    # F7 function key
    def key_f7
    end

    # F8 function key
    def key_f8
    end

    # F9 function key
    def key_f9
    end

    # find key
    def key_find
    end

    # help key
    def key_help
    end

    # home key
    def key_home
    end

    # insert-character key
    def key_ic
    end

    # insert-line key
    def key_il
    end

    # left-arrow key
    def key_left
    end

    # lower-left key (home down)
    def key_ll
    end

    # mark key
    def key_mark
    end

    # message key
    def key_message
    end

    # move key
    def key_move
    end

    # next key
    def key_next
    end

    # next-page key
    def key_npage
    end

    # open key
    def key_open
    end

    # options key
    def key_options
    end

    # previous-page key
    def key_ppage
    end

    # previous key
    def key_previous
    end

    # print key
    def key_print
    end

    # redo key
    def key_redo
    end

    # reference key
    def key_reference
    end

    # refresh key
    def key_refresh
    end

    # replace key
    def key_replace
    end

    # restart key
    def key_restart
    end

    # resume key
    def key_resume
    end

    # right-arrow key
    def key_right
    end

    # save key
    def key_save
    end

    # shifted begin key
    def key_sbeg
    end

    # shifted cancel key
    def key_scancel
    end

    # shifted command key
    def key_scommand
    end

    # shifted copy key
    def key_scopy
    end

    # shifted create key
    def key_screate
    end

    # shifted delete-character key
    def key_sdc
    end

    # shifted delete-line key
    def key_sdl
    end

    # select key
    def key_select
    end

    # shifted end key
    def key_send
    end

    # shifted clear-to- end-of-line key
    def key_seol
    end

    # shifted exit key
    def key_sexit
    end

    # scroll-forward key
    def key_sf
    end

    # shifted find key
    def key_sfind
    end

    # shifted help key
    def key_shelp
    end

    # shifted home key
    def key_shome
    end

    # shifted insert-character key
    def key_sic
    end

    # shifted left-arrow key
    def key_sleft
    end

    # shifted message key
    def key_smessage
    end

    # shifted move key
    def key_smove
    end

    # shifted next key
    def key_snext
    end

    # shifted options key
    def key_soptions
    end

    # shifted previous key
    def key_sprevious
    end

    # shifted print key
    def key_sprint
    end

    # scroll-backward key
    def key_sr
    end

    # shifted redo key
    def key_sredo
    end

    # shifted replace key
    def key_sreplace
    end

    # shifted right-arrow key
    def key_sright
    end

    # shifted resume key
    def key_srsume
    end

    # shifted save key
    def key_ssave
    end

    # shifted suspend key
    def key_ssuspend
    end

    # set-tab key
    def key_stab
    end

    # shifted undo key
    def key_sundo
    end

    # suspend key
    def key_suspend
    end

    # undo key
    def key_undo
    end

    # up-arrow key
    def key_up
      self.y -= 1
    end

    # leave 'keyboard_transmit' mode
    def keypad_local
    end

    # enter 'keyboard_transmit' mode
    def keypad_xmit
    end

    # label on function key f0 if not f0
    def lab_f0
    end

    # label on function key f1 if not f1
    def lab_f1
    end

    # label on function key f10 if not f10
    def lab_f10
    end

    # label on function key f2 if not f2
    def lab_f2
    end

    # label on function key f3 if not f3
    def lab_f3
    end

    # label on function key f4 if not f4
    def lab_f4
    end

    # label on function key f5 if not f5
    def lab_f5
    end

    # label on function key f6 if not f6
    def lab_f6
    end

    # label on function key f7 if not f7
    def lab_f7
    end

    # label on function key f8 if not f8
    def lab_f8
    end

    # label on function key f9 if not f9
    def lab_f9
    end

    # label format
    def label_format
    end

    # turn off soft labels
    def label_off
    end

    # turn on soft labels
    def label_on
    end

    # turn off meta mode
    def meta_off
    end

    # turn on meta mode (8th-bit on)
    def meta_on
    end

    # Like column_address in micro mode
    def micro_column_address
    end

    # Like cursor_down in micro mode
    def micro_down
    end

    # Like cursor_left in micro mode
    def micro_left
    end

    # Like cursor_right in micro mode
    def micro_right
    end

    # Like row_address #1 in micro mode
    def micro_row_address
    end

    # Like cursor_up in micro mode
    def micro_up
    end

    # newline (behave like cr followed by lf)
    def newline
      self.y += 1
      self.x = 0
      insert("#{y}.#{x}", "\n")
      adjust_insert
    end

    # Match software bits to print-head pins
    def order_of_pins
    end

    # Set all color pairs to the original ones
    def orig_colors
    end

    # Set default pair to its original value
    def orig_pair
    end

    # padding char (instead of null)
    def pad_char
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
    def parm_left_cursor
      self.x -= count
      adjust_insert
    end

    # Like parm_left_cursor in micro mode
    def parm_left_micro
    end

    # move #1 characters to the right (P*)
    def parm_right_cursor(count)
      self.x += count
      adjust_insert
    end

    # Like parm_right_cursor in micro mode
    def parm_right_micro
    end

    # scroll back #1 lines (P)
    def parm_rindex
    end

    # up #1 lines (P*)
    def parm_up_cursor
      self.y -= count
      adjust_insert
    end

    # Like parm_up_cursor in micro mode
    def parm_up_micro
    end

    # program function key #1 to type string #2
    def pkey_key
    end

    # program function key #1 to execute string #2
    def pkey_local
    end

    # program function key #1 to transmit string #2
    def pkey_xmit
    end

    # program label #1 to show string #2
    def plab_norm
    end

    # print contents of screen
    def print_screen
    end

    # turn on printer for #1 bytes
    def prtr_non
    end

    # turn off printer
    def prtr_off
    end

    # turn on printer
    def prtr_on
    end

    # select pulse dialing
    def pulse
    end

    # dial number #1 without checking
    def quick_dial
    end

    # remove clock
    def remove_clock
    end

    # repeat char #1 #2 times (P*)
    def repeat_char
    end

    # send next input char (for ptys)
    def req_for_input
    end

    # reset string
    def reset_1string
    end

    # reset string
    def reset_2string
    end

    # reset string
    def reset_3string
    end

    # name of reset file
    def reset_file
    end

    # restore cursor to position of last save_cursor
    def restore_cursor
    end

    # vertical position #1 absolute (P)
    def row_address(row)
      self.y = row
      adjust_insert
    end

    # save current cursor position (P)
    def save_cursor
    end

    # scroll text up (P)
    def scroll_forward
    end

    # scroll text down (P)
    def scroll_reverse
    end

    # Select character set, #1
    def select_char_set
    end

    # define video attributes #1-#9 (PG9)
    def set_attributes
    end

    # Set background color #1
    def set_background(*indices)
      if indices.empty? || indices == ANSI_RESET
        @foreground = BRIGHT_WHITE
        @background = DARK_BLACK
      else
        indices.each do |index|
          index = index.to_i

          if bg = TERM_COLORS[index]
            @background = bg
          elsif fg = TERM_COLORS[index]
            @foreground = fg
          elsif at = TERM_ATTRIBUTES[index]
            @attribute = at
          else
            Kernel.warn "set_background(#{indices.inspect})"
          end
        end
      end

      update_tag
    end

    # Set bottom margin at current line
    def set_bottom_margin
    end

    # Set bottom margin at line #1 or (if smgtp is not given) #2 lines from bottom
    def set_bottom_margin_parm
    end

    # set clock, #1 hrs #2 mins #3 secs
    def set_clock
    end

    # Set current color pair to #1
    def set_color_pair
    end

    # Set foreground color #1
    def set_foreground(*indices)
      if indices.empty? || indices == ANSI_RESET
        @foreground = BRIGHT_WHITE
        @background = DARK_BLACK
      else
        indices.each do |index|
          index = index.to_i

          if fg = TERM_COLORS[index]
            @foreground = fg
          elsif bg = TERM_COLORS[index]
            @background = bg
          elsif at = TERM_ATTRIBUTES[index]
            @attribute = at
          else
            Kernel.warn "set_foreground(#{indices.inspect})"
          end
        end
      end

      update_tag
    end

    # set left soft margin at current column. See smgl. (ML is not in BSD termcap).
    def set_left_margin
    end

    # Set left (right) margin at column #1
    def set_left_margin_parm
    end

    # set right soft margin at current column
    def set_right_margin
    end

    # Set right margin at column #1
    def set_right_margin_parm
    end

    # set a tab in every row, current columns
    def set_tab
    end

    # Set top margin at current line
    def set_top_margin
    end

    # Set top (bottom) margin at row #1
    def set_top_margin_parm
    end

    # current window is lines #1-#2 cols #3-#4
    def set_window
    end

    # Start printing bit image graphics
    def start_bit_image
    end

    # Start character set definition #1, with #2 characters in the set
    def start_char_set_def
    end

    # Stop printing bit image graphics
    def stop_bit_image
    end

    # End definition of character set #1
    def stop_char_set_def
    end

    # List of subscriptable characters
    def subscript_characters
    end

    # List of superscriptable characters
    def superscript_characters
    end

    # tab to next 8-space hardware tab stop
    def tab
    end

    # Printing any of these characters causes CR
    def these_cause_cr
    end

    # move to status line, column #1
    def to_status_line
    end

    # select touch tone dialing
    def tone
    end

    # underline char and move past it
    def underline_char
    end

    # half a line up
    def up_half_line
    end

    # User string #0
    def user0
    end

    # User string #1
    def user1
    end

    # User string #2
    def user2
    end

    # User string #3
    def user3
    end

    # User string #4
    def user4
    end

    # User string #5
    def user5
    end

    # User string #6
    def user6
    end

    # User string #7
    def user7
    end

    # User string #8
    def user8
    end

    # User string #9
    def user9
    end

    # wait for dial-tone
    def wait_tone
    end

    # XOFF character
    def xoff_character
    end

    # XON character
    def xon_character
    end

    # No motion for subsequent character
    def zero_motion
    end

    # Alternate escape for scancode emulation
    def alt_scancode_esc
    end

    # Move to beginning of same row
    def bit_image_carriage_return
    end

    # Move to next row of the bit image
    def bit_image_newline
    end

    # Repeat bit image cell #1 #2 times
    def bit_image_repeat
    end

    # Produce #1'th item from list of character set names
    def char_set_names
    end

    # Init sequence for multiple codesets
    def code_set_init
    end

    # Give name for color #1
    def color_names
    end

    # Define rectangualar bit image region
    def define_bit_image_region
    end

    # Indicate language/codeset support
    def device_type
    end

    # Display PC character #1
    def display_pc_char
    end

    # End a bit-image region
    def end_bit_image_region
    end

    # Enter PC character display mode
    def enter_pc_charset_mode
    end

    # Enter PC scancode mode
    def enter_scancode_mode
    end

    # Exit PC character display mode
    def exit_pc_charset_mode
    end

    # Exit PC scancode mode
    def exit_scancode_mode
    end

    # Curses should get button events, parameter #1 not documented.
    def get_mouse
    end

    # Mouse event has occurred
    def key_mouse
    end

    # Mouse status information
    def mouse_info
    end

    # PC terminal options
    def pc_term_options
    end

    # Program function key #1 to type string #2 and show string #3
    def pkey_plab
    end

    # Request mouse position
    def req_mouse_pos
    end

    # Escape for scancode emulation
    def scancode_escape
    end

    # Shift to codeset 0 (EUC set 0, ASCII)
    def set0_des_seq
    end

    # Shift to codeset 1
    def set1_des_seq
    end

    # Shift to codeset 2
    def set2_des_seq
    end

    # Shift to codeset 3
    def set3_des_seq
    end

    # Set background color to #1, using ANSI escape
    def set_a_background(name)
      @background = ANSI_COLORS.fetch(name)
      update_tag
    end

    # Set foreground color to #1, using ANSI escape
    def set_a_foreground(name)
      @foreground = ANSI_COLORS.fetch(name)
      update_tag
    end

    # Change to ribbon color #1
    def set_color_band
    end

    # Set both left and right margins to #1, #2. (ML is not in BSD termcap).
    def set_lr_margin
    end

    # Set page length to #1 lines
    def set_page_length
    end

    # Sets both top and bottom margins to #1, #2
    def set_tb_margin
    end

    # Enter horizontal highlight mode
    def enter_horizontal_hl_mode
    end

    # Enter left highlight mode
    def enter_left_hl_mode
    end

    # Enter low highlight mode
    def enter_low_hl_mode
    end

    # Enter right highlight mode
    def enter_right_hl_mode
    end

    # Enter top highlight mode
    def enter_top_hl_mode
    end

    # Enter vertical highlight mode
    def enter_vertical_hl_mode
    end

    # Define second set of video attributes #1-#6
    def set_a_attributes
    end

    # YI Set page length to #1 hundredth of an inch
    def set_pglen_inch
    end

    # start alternate character set (P)
    def enter_alt_charset_mode
    end

    # turn on automatic margins
    def enter_am_mode
    end

    # turn on blinking
    def enter_blink_mode
    end

    # turn on bold (extra bright) mode
    def enter_bold_mode
    end

    # string to start programs using cup
    def enter_ca_mode
      delete(1.0, :end)
    end

    # enter delete mode
    def enter_delete_mode
    end

    # turn on half-bright mode
    def enter_dim_mode
    end

    # Enter double-wide mode
    def enter_doublewide_mode
    end

    # Enter draft-quality mode
    def enter_draft_quality
    end

    # enter insert mode
    def enter_insert_mode
    end

    # Enter italic mode
    def enter_italics_mode
    end

    # Start leftward carriage motion
    def enter_leftward_mode
    end

    # Start micro-motion mode
    def enter_micro_mode
    end

    # Enter NLQ mode
    def enter_near_letter_quality
    end

    # Enter normal-quality mode
    def enter_normal_quality
    end

    # turn on protected mode
    def enter_protected_mode
    end

    # turn on reverse video mode
    def enter_reverse_mode
    end

    # turn on blank mode (characters invisible)
    def enter_secure_mode
    end

    # Enter shadow-print mode
    def enter_shadow_mode
    end

    # begin standout mode
    def enter_standout_mode
    end

    # Enter subscript mode
    def enter_subscript_mode
    end

    # Enter superscript mode
    def enter_superscript_mode
    end

    # begin underline mode
    def enter_underline_mode
    end

    # Start upward carriage motion
    def enter_upward_mode
    end

    # turn on xon/xoff handshaking
    def enter_xon_mode
    end

    # end alternate character set (P)
    def exit_alt_charset_mode
    end

    # turn off automatic margins
    def exit_am_mode
    end

    # turn off all attributes
    def exit_attribute_mode
    end

    # strings to end programs using cup
    def exit_ca_mode
    end

    # end delete mode
    def exit_delete_mode
    end

    # End double-wide mode
    def exit_doublewide_mode
    end

    # exit insert mode
    def exit_insert_mode
    end

    # End italic mode
    def exit_italics_mode
    end

    # End left-motion mode
    def exit_leftward_mode
    end

    # End micro-motion mode
    def exit_micro_mode
    end

    # End shadow-print mode
    def exit_shadow_mode
    end

    # exit standout mode
    def exit_standout_mode
    end

    # End subscript mode
    def exit_subscript_mode
    end

    # End superscript mode
    def exit_superscript_mode
    end

    # exit underline mode
    def exit_underline_mode
    end

    # End reverse character motion
    def exit_upward_mode
    end

    # turn off xon/xoff
    def exit_xon_mode
    end

    # start programs using cup
    def enter_ca_mode
      # Kernel.raise NotImplementedError
    end

    # end programs using cup
    def exit_ca_mode
    end

    # turn on automatic margins
    def enter_am_mode
    end
  end
end
