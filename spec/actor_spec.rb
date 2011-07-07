require File.join(File.dirname(__FILE__), "spec_helper")
require "yaram/actor"

describe Yaram::StartError do
  it { should be_a Yaram::StandardError }
  it "should be a Yaram::Error" do
    expect {
      raise Yaram::StartError
    }.to raise_error(Yaram::Error)
  end # it "should be a Yaram::Error"
end # describe Yaram::StartError

describe Yaram::Actor::Base do
  it { should be_a Yaram::Actor::Base }
end # describe Yaram::Base