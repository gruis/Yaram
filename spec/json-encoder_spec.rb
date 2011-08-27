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

module Yaram
  module GzipEncoder
    extend Encoder
  end # module::GzipEncoder
end # module::Yaram

module Yaram
  module BzipEncoder
    extend Encoder
  end # module::BzipEncoder
end # module::Yaram

describe "Yaram::JsonEncoder" do
  it "should replace the GenericEncoder" do
    Yaram::Encoder.last.should == Yaram::JsonEncoder
  end # should replace the GenericEncoder
end # "Yaram::JsonEncoder"


describe "Yaram::Encoder.replace" do
  before(:each) do
    Yaram.encoder = Yaram::GenericEncoder
    Yaram::Encoder.inject(Yaram::GzipEncoder)
    Yaram::Encoder.inject(Yaram::BzipEncoder)
  end # 
  after(:all) do
    Yaram.encoder = Yaram::GenericEncoder    
  end #
  
  it "should replace the last encoder (GenericEncoder)" do
    Yaram::Encoder.replace(Yaram::GenericEncoder, Yaram::JsonEncoder)
    Yaram::Encoder.last.should == Yaram::JsonEncoder
  end # should replace the GenericEncoder
  
  it "should replace the first encoder" do
    Yaram::Encoder.replace(Yaram::BzipEncoder, Yaram::JsonEncoder)
    Yaram::Encoder.all[0].should == Yaram::JsonEncoder
  end # should replace the first encoder

  it "should replace the middle encoder" do
    Yaram::Encoder.replace(Yaram::GzipEncoder, Yaram::JsonEncoder)
    Yaram::Encoder.all[1].should == Yaram::JsonEncoder
  end # should replace the first encoder

end # Yaram::Encoder.replace

