require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram::Mongodb do
  it "should have a VERSION" do
    Yaram::Mongodb.const_defined?(:VERSION).should be true
  end # it "should have a VERSION"

  describe "VERSION" do
    subject { Yaram::Mongodb::VERSION }
    it { should be_a String }
  end # describe "VERSION"
end # describe Yaram::Mongodb


describe Yaram::Mongodb::Mailbox do
  it "should be builable from Yaram::Mailbox" do
    Yaram::Mailbox.build("mongodb://127.0.0.1/abcdefg").should be_a(Yaram::Mongodb::Mailbox)
  end # should be builable from Yaram::Mailbox
  it "should be buildable from Yaram::Mailbox::Mongodb" do
    Yaram::Mailbox.build(Yaram::Mailbox::Mongodb).should be_a(Yaram::Mongodb::Mailbox)
  end # should be buildable from Yaram::Mailbox::Mongodb
  
  it "should pass messages" do
    actor = Yaram::Actor::Proxy.new(Yaram::Mongodb::Test::MCounter.new.spawn(:log => "mongo", :mailbox => Yaram::Mailbox::Mongodb))
    actor.sync(:status).should == :up
  end # should pass messages
end # Yaram::Mongodb::Mailbox
