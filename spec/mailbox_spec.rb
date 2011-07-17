require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do
  it "should work with memory mailboxs" do
    actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false)
    actor.sync(:status).should == :up
  end # it should work with memory mailboxs
  
  describe "udp mailbox" do
    it "should work with udp mailboxs" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false, :mailbox => Yaram::Mailbox::Udp)
      actor.sync(:status).should == :up
    end # it should work with udp mailboxs      
    it "should provide an address for external actors" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false, :mailbox => Yaram::Mailbox::Udp)
      actor.address.should include("udp")
      actor.sync(:address).should_not be actor.address
    end # it should provide an address for external actors
  end # "udp mailboxs"
  
  describe "fifo mailbox" do
    it "should work with fifo mailboxs" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false, :mailbox => Yaram::Mailbox::Fifo)
      actor.sync(:status).should == :up
    end # it should work with fifo mailboxs    
  end # "fifo mailbox"

  it "should work with tcp mailboxs" do
    actor = Yaram::Actor::Simple.new(Yaram::Test::Actor, :log => false, :mailbox => Yaram::Mailbox::Tcp)
    actor.sync(:status).should == :up
  end # it should work with tcp mailboxs  
end # describe Yaram