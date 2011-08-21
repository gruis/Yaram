require File.join(File.dirname(__FILE__), "spec_helper")

class PoolCounter
  def initialize(value = 0)
    @count = value
  end # initialize(count = 0)
  def inc(num)
    @count += num
  end # inc(num)
  def value
    @count
  end # value
  def pid
    Process.pid
  end # pid
end # class::PoolCounter < Yaram::Actor::Base

describe "Yaram::Actor::Pool" do
  
  it "should divide work up among the pool members" do
    actors    = []
    3.times { |i| actors.push(Yaram::Actor.start(PoolCounter.new, :log => false)) }
    
    addresses = actors.map{|p| p.outbox.address }
    
    pool       = Yaram::Actor::Pool.new(*addresses, :log => false, :mailbox => Yaram::Mailbox::Udp)
    pool.members.should == addresses
    pool.sync(:inc, 10).should == 10
    
    pids = []
    6.times { pids.push(pool.sync(:pid)) }
    # If the work is all going to only one of the actors this example will fail
    pids.count(pids[0]).should_not == pids.length
  end # should divide work up among the pool members
  
  describe ".connect" do
    it "should connect to a running Pool" do
      actors    = []
      3.times { |i| actors.push(Yaram::Actor.start(PoolCounter.new, :log => false)) }
      addresses = actors.map{|p| p.outbox.address }
      pool       = Yaram::Actor::Pool.new(*addresses, :log => false, :mailbox => Yaram::Mailbox::Udp)
      other_pool = Yaram::Actor::Pool.connect(pool.address)
      other_pool.should_not == pool
      other_pool.members.should == pool.members
    end # should connect to a running Pool
  end # .connect
end # "Yaram::Actor::Pool"
