require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do
  it "should work with the default type of mailbox" do
    actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false))
    actor.sync(:status).should == :up
  end # it should work with memory mailboxs
  
  describe "udp mailbox" do
    it "should work with udp mailboxs" do
      actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Udp))
      actor.sync(:status).should == :up
    end # it should work with udp mailboxs      
    it "should provide an address for external actors" do
      actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Udp))
      actor.address.should include("udp")
      actor.sync(:address).should_not be actor.address
    end # it should provide an address for external actors
    
    it "should allow the caller to define the address of the actor" do
      actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => "udp://127.0.0.1:5897"))
      actor.outbox.address.should == "udp://127.0.0.1:5897"
      actor.sync(:status).should == :up
    end # it should allow the caller to define the address of the actor  
  end # "udp mailboxs"
  
  describe "fifo mailbox" do
    it "should work with fifo mailboxs" do
      actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Fifo))
      actor.sync(:status).should == :up
    end # it should work with fifo mailboxs    
  end # "fifo mailbox"

  it "should work with tcp mailboxes" do
    actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Tcp))
    actor.sync(:status).should == :up
  end # it should work with tcp mailboxs  
end # describe Yaram