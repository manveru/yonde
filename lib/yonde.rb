require 'ffi-tk'
require 'thread'
require 'strscan'
require 'pty'

# Yonda is a terminal emulator using Tk for display.
#
# TODO:
#   * Use ioctl to inform about the size of the window, until then we have to
#     use the size specified in the terminfo
class Yonde < Struct.new(:parent, :buffer, :controller)
  def self.require_lib
    require 'yonde/buffer'
    require 'yonde/pty'
    require 'yonde/controller'
  end

  def initialize(parent = Tk.root)
    self.parent = parent
    self.buffer = Buffer.new(parent)
    self.controller = Controller.new(buffer)
  end

  def <<(input)
    controller.call(input)
  end

  def content
    buffer.value.chomp
  end
end

begin
  Yonde.require_lib
rescue LoadError
  $LOAD_PATH.unshift(File.dirname(__FILE__))
  Yonde.require_lib
end
