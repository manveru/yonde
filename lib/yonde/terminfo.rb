class Yonde
  # Load given terminfo, if it's a file, we will use tic to pretty-print it and
  # parse the output.
  # If you don't have the original terminfo, you should pass the name of the
  # terminal.
  #
  # Returns a Hash with all the information parsed.
  #
  # FIXME:
  #   ^x maps to a control-x for any appropriate x
  def self.parse_terminfo(term_or_terminfo)
    cmd = File.file?(term_or_terminfo) ? 'tic' : 'infocmp'
    string = `#{cmd} -L1 '#{term_or_terminfo}'`

    set = {}
    term = nil

    string.each_line do |line|
      line.strip!

      case line
      when /^#/ # ignore comments
      when /^([a-z0-9-]+)\|(.*),$/
        term = $1, $2
      when /^(\w+),/
        set[$1.to_sym] = true
      when /^(\w+)=(.*),$/
        set[$1.to_sym] = $2.
          gsub(/\\([0-9]{3})/){|n| $1.to_i(8).chr }.
          gsub(/\\e/i, "\e")
          # gsub(/\\,/, ',').
          # gsub(/\\e/i, "\e").
          # gsub(/\\:/, ':').
          # gsub(/\\\\/, '\\\\').
          # gsub(/\\[0-9]{3}/){|n| n.to_i(8) }.
          # gsub(/\\\^/, '^')
      when /^(\w+)#(\d+),$/
        set[$1.to_sym] = $2.to_i
      when /^(\w+)@,$/ # canceled capability
      else
        fail line
      end
    end

    return set
  end
end
