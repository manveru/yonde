class Yonde
  # largest Fixnum on 32 bit, try to optimize a bit more.
  PTY_READ_LENGTH = ((1 << 30) - 1)

  def self.pty(queue, callback = nil, &block)
    callback ||= block
    outbuf = ''

    Thread.new do
      ENV['TERM'] = 'rxvt-unicode' # let's hope you have it :)
      shell = ENV['SHELL'] || 'bash'

      PTY.spawn(shell) do |r_pty, w_pty, pid|
        w_pty.sync = true

        Thread.new do
          while chunk = queue.shift
            w_pty.print chunk
          end
        end

        begin
          loop do
            r_pty.readpartial(PTY_READ_LENGTH, outbuf)
            callback.call(outbuf)
          end
        rescue Errno::EIO, PTY::ChildExited
          callback.destroy
        end
      end
    end
  rescue Errno::EIO, PTY::ChildExited
    callback.destroy
  end
end
