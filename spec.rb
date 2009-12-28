require 'bacon'
Bacon.summary_on_exit

require_relative 'lib/yonde'

describe Yonde do
  yonde = Yonde.new

  it 'starts out empty' do
    yonde.content.should.be.empty
  end

  it 'inserts a character' do
    yonde << 'a'
    yonde.content.should == "a"
  end

  it 'inserts multiple characters' do
    yonde << 'sdf'
    yonde.content.should == "asdf"
  end

  it 'deletes a character' do
    yonde << "\b"
    yonde.content.should == "asd "
  end

  it 'handles carriage-return' do
    yonde << "\r"
    yonde.content.should == "asd "
    yonde << "done"
    yonde.content.should == "done"
  end

  it 'inserts newlines' do
    yonde << "\n"
    yonde.content.should == "done\n"
  end

  it 'stays on the line even after a few carriage-returns' do
    yonde << "bar\r\r\rfoo"
    yonde.content.should == "done\nfoo"
  end

  def cursor_address(row, col)
    "\e[#{row.to_int};#{col.to_int}H"
  end

  it 'can move to a non-written col on the first line' do
    yonde << cursor_address(1, 20)
    yonde << "yay"
    yonde.content.should == "done                yay\nfoo"
    yonde << "\b"
    yonde.content.should == "done                ya \nfoo"
  end
end
