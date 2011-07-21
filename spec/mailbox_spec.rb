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

  describe "unix domain socket mailbox" do
    it "should work with domain sockets" do
      actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:mailbox => Yaram::Mailbox::Unix, :log => false))
      actor.sync(:status).should == :up      
    end # it should work with domain sockets
    it "should support multiple client connections" do
      addr = Yaram::Test::MCounter.new.spawn(:mailbox => Yaram::Mailbox::Unix, :log => false)
      c0 = Yaram::Actor::Proxy.new(addr)
      c1 = Yaram::Actor::Proxy.new(addr)
      c2 = Yaram::Actor::Proxy.new(addr)
      c1.!(:inc, 1)
      c0.sync(:status).should == :up
      c2.!(:inc, 3)
      c1.!(:inc, 3)
      c2.sync(:status).should == :up
      c1.sync(:status).should == :up
      c0.sync(:status).should == :up
      c0.sync(:value).should == 7
    end # it should support multiple client connections
    
    it "should be fast" do
      actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:mailbox => Yaram::Mailbox::Unix, :log => false))
      actor.!(:inc, 1) # initial connection setup takes about 0.03 seconds
      sleep 1
      expect {
        100000.times { actor.!(:inc, 1) } 
      }.to take_less_than(1).seconds
    end # it should be fast  
  end # "unix domain socket mailbox"

  it "should work with tcp mailboxes" do
    actor = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Tcp))
    actor.sync(:status).should == :up
  end # it should work with tcp mailboxs  
end # describe Yaram