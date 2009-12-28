class Yonde
  def self.pty(queue, callback = nil, &block)
    callback ||= block

    Thread.new do
      ENV['TERM'] = 'rxvt-unicode' # let's hope you have it :)
      shell = ENV['SHELL'] || 'bash'

      PTY.spawn(shell) do |r_pty, w_pty, pid|
        Thread.new do
          while chunk = queue.shift
            w_pty.print chunk
            w_pty.flush
          end
        end

        begin
          loop do
            c = r_pty.sysread(1) # (1 << 15)
            callback.call(c) if c
          end
        rescue Errno::EIO, PTY::ChildExited
          destroy
        end
      end
    end
  rescue Errno::EIO, PTY::ChildExited
    destroy
  end
end
