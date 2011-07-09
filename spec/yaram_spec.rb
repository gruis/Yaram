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

  it "should http://ruben.savanne.be/articles/concurrency-in-erlang-scala" do
    counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false)
    cnt = 10000
    cnt.times { counter.!(:inc, 1) }
    counter.sync(:value).should == cnt
  end # it should http://ruben.savanne.be/articles/concurrency-in-erlang-scala
  
  describe "performance and reliablity" do
    before(:each) { @counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false) }
    after(:each) { @counter.stop }
    [100, 1000, 10000, 100000, 1000000].each do |cnt|
      it "should support #{cnt} requests" do
        cnt.times { @counter.recover(1) { @counter.!(:inc, 1) } }
        @counter.sync(:value).should == cnt
      end # it should support #{}
    end #  |cnt|

    it "should execute 175,000 requests per second" do
      expect {
        175000.times { @counter.recover(1) { @counter.!(:inc, 1) } }
      }.to take_less_than(1.0).seconds
    end # it should take less than x seconds  

    it "should execute 140,000 requests per second over Udp" do
      begin
        counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false, :pipe => Yaram::Pipe::Udp.new)
        expect {
          140000.times { counter.recover(1) { counter.!(:inc, 1) } }
        }.to take_less_than(1.0).seconds        
      ensure
        counter.stop
      end # begin
    end # it should take less than x seconds  
    
    it "should return responses to requests even if other messages are in the queue" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::MultiReplyActor, :log => false)
      actor.sync(:status).should == :up
    end # it should return responses to requests even if other messages are in the queue  
  end # "performance and reliablity"
  
end # describe Yaram
