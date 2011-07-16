require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do
  it "should have a VERSION" do
    Yaram.const_defined?(:VERSION).should be true
  end # it "should have a VERSION"
  describe "VERSION" do
    subject { Yaram::VERSION }
    it { should be_a String }
  end # describe "VERSION"


  it "should work with memory pipes" do
    actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false)
    actor.sync(:status).should == :up
  end # it should work with memory pipes  

  it "should work with udp pipes" do
    actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false, :pipe => Yaram::Pipe::Udp)
    actor.sync(:status).should == :up
  end # it should work with udp pipes  

  it "should work with tcp pipes" do
    actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false, :pipe => Yaram::Pipe::Tcp)
    actor.sync(:status).should == :up
  end # it should work with tcp pipes  
end # describe Yaram