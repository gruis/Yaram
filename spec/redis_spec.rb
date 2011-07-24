require File.join(File.dirname(__FILE__), "spec_helper")
require "stringio"

describe Yaram::Mailbox::Redis do
  before(:all) do
    @msgs = IO.read(File.join(File.dirname(__FILE__), "data", "redis.msgs.txt"))
  end # :all
  before(:each) do
    subject.instance_variable_set(:@io, StringIO.new(@msgs))
  end # :each
  it "should parse redis messages" do
    puts subject.read
    subject.read.split("]]>]]>").length.should == 12
    
    expect {
      subject.read.split("]]>]]>").map{|m| Yaram.encoder.load(m) }
    }.to_not raise_error
  end # should parse redis messages
end # Yaram::Mailbox::Redis