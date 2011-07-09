require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do

  it "should comply with http://ruben.savanne.be/articles/concurrency-in-erlang-scala" do
    counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false)
    cnt = 10000
    cnt.times { counter.!(:inc, 1) }
    counter.sync(:value).should == cnt
  end # it should comply with http://ruben.savanne.be/articles/concurrency-in-erlang-scala
  
  describe "reliablity" do
    before(:each) { @counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false) }
    after(:each) { @counter.stop }
    
    it "should return responses to requests even if other messages are in the queue" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::MultiReplyActor, :log => false)
      actor.sync(:status).should == :up
    end # it should return responses to requests even if other messages are in the queue  
  end # "performance and reliablity"
  
end # describe Yaram
