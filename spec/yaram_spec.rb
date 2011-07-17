require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do

  it "should comply with http://ruben.savanne.be/articles/concurrency-in-erlang-scala" do
    counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false)
    cnt = 2000
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


  describe "implicit and explicit replies" do
    it "should return the result of the actor's method if the actor doesn't call reply explicitly" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::ImplicitReplyActor, :log => false)
      actor.sync(:status).should == :implicit
    end # it should return the result of the actor's method if the actor doesn't call reply explicitly  
    it "should not return the result of the actor's method if the actor calls reply explicitly" do
      actor = Yaram::Actor::Simple.new(Yaram::Test::ExplicitReplyActor, :log => false)
      actor.sync(:status).should == :explicit
    end # it should not return teh result of the actor's method if the actor calls reply explicitly  
  end # "implicit and explicit replies"


  describe "pattern matching" do
    it "should support pattern matching" 
  end # "pattern matching"

  describe "starting an actor exclusively for use by this actor" do
    pending
  end # "starting a child process actor"
  describe "starting an actor that other actors can use" do
    pending
  end # "starting an actor that other actors will use"

end # describe Yaram
