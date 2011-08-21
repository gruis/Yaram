require File.join(File.dirname(__FILE__), "spec_helper")

class PoolCounter < Yaram::Actor::Base
  include Yaram::Actor::Pool::Member
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
    3.times { actors.push(Yaram::Actor.start(PoolCounter.new, :log => false)) }
    
    addresses = actors.map{|p| p.outbox.address }
    pool      = Yaram::Actor::Proxy.new(Yaram::Actor::Pool.new(*addresses, :log => false).address)
    
    pool.sync(:members).should == addresses
    pool.sync(:inc, 10).should == 10
    
    pids = []
    6.times { pids.push(pool.sync(:pid)) }
    # If the work is all going to only one of the actors this example will fail
    pids.count(pids[0]).should_not == pids.length
  end # should divide work up among the pool members
  
end # "Yaram::Actor::Pool"
