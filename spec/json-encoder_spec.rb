require File.join(File.dirname(__FILE__), "spec_helper")
require "yaram/json-encoder"

class Counter
  def initialize(value = 0)
    @count = value
  end # initialize(count = 0)
  def inc(num)
    @count += num
  end # inc(num)
  def value
    @count
  end # value
end # class::PoolCounter < Yaram::Actor::Base

describe "Yaram::JsonEncoder" do
  it "should replace the GenericEncoder" do
    Yaram.encoder.first.should be_a(Yaram::JsonEncoder)
  end # should replace the GenericEncoder
end # "Yaram::JsonEncoder"
