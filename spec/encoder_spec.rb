require File.join(File.dirname(__FILE__), "spec_helper")

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
  class GzipEncoder
    include Encoder
    prefix 'yaram:gzip: '
    def dump(o) @prefix + o; end # dump(o)
    def load(o) o[12..-1]; end # load(o)
  end # class::GzipEncoder
  class BzipEncoder
    include Encoder
    prefix 'yaram:bzip: '
    def dump(o) @prefix + o; end # dump(o)
    def load(o) o[12..-1]; end # load(o)
  end # class::BzipEncoder
  class FunkyEncoder
    include Encoder
    prefix 'yaram:funky:'
    def dump(o) @prefix + o; end # dump(o)
    def load(o) o[12..-1]; end # load(o)
  end # class::FunkyEncoder
end # module::Yaram



describe "Yaram::Encoder" do
  describe "newchain" do
    it "should construct chains from Classes" do
      chain  = Yaram::Encoder.newchain(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder)
      chain[0].should be_a(Yaram::GenericEncoder)
      chain[1].should be_a(Yaram::GzipEncoder)
      chain[2].should be_a(Yaram::BzipEncoder)
    end # should construct chains from Classes
    it "should construct chains from Class instances" do
      chain  = Yaram::Encoder.newchain((ge = Yaram::GenericEncoder.new), (gze = Yaram::GzipEncoder.new), (be = Yaram::BzipEncoder.new))
      chain[0].should == ge
      chain[1].should == gze
      chain[2].should == be
    end # should construct chains from Class instnaces
    it "should construct chains from prefixes" do
      chainprefixes = "#{Yaram::GenericEncoder.prefix},#{Yaram::GzipEncoder.prefix},#{Yaram::BzipEncoder.prefix}"
      chain  = Yaram::Encoder.newchain(chainprefixes)
      chain[0].should be_a(Yaram::GenericEncoder)
      chain[1].should be_a(Yaram::GzipEncoder)
      chain[2].should be_a(Yaram::BzipEncoder)

      chainprefixes = "#{Yaram::GenericEncoder.prefix},#{Yaram::GzipEncoder.prefix}"
      chain  = Yaram::Encoder.newchain(chainprefixes)
      chain[0].should be_a(Yaram::GenericEncoder)
      chain[1].should be_a(Yaram::GzipEncoder)

      chainprefixes = "#{Yaram::GenericEncoder.prefix}"
      chain  = Yaram::Encoder.newchain(chainprefixes)
      chain[0].should be_a(Yaram::GenericEncoder)
    end # should construct chains from prefixes
    
    it "should reuse previously constructed encoder chains" do
      pending
      Yaram::Encoder.newchain(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder).should == Yaram::Encoder.newchain(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder)
    end # should reuse previously constructed encoder chains
  end # newchain
  
  describe ".replace" do
    before(:each) do
      Yaram.encoder = Yaram::Encoder.newchain(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder)
    end #
    after(:all) do
      Yaram.encoder = Yaram::Encoder.newchain(Yaram::GenericEncoder)
    end #

    # @todo add test for inject raising error when supplied encoder doesn't have a settable encoder attribute

    it "should replace the first encoder" do
      Yaram.encoder.replace(Yaram::GenericEncoder, Yaram::FunkyEncoder)
      Yaram.encoder.first.should be_a(Yaram::FunkyEncoder)
    end # should replace the first encoder

    it "should replace the last encoder" do
      Yaram.encoder.replace(Yaram::BzipEncoder, Yaram::FunkyEncoder)
      Yaram.encoder.last.should be_a(Yaram::FunkyEncoder)
    end # should replace the last encoder

    it "should replace the middle encoder" do
      Yaram.encoder.replace(Yaram::GzipEncoder, Yaram::FunkyEncoder)
      Yaram.encoder.all[1].should be_a(Yaram::FunkyEncoder)
    end # should replace the first encoder
  end # .replace
  
  describe ".dump" do
    it "should call each encoder starting with the first" do
      chain = Yaram::Encoder.newchain(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder)
      chain.dump("thing are not alaways what they seem").start_with?("yaram:bzip: yaram:gzip: yaram:ox:   ").should == true 
    end # should call each encoder starting with the first
    it "should call each encoder starting with the last" do
      chain = Yaram::Encoder.newchain(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder)
      enc = chain.dump("thing are not alaways what they seem")
      chain.load(enc).should == "thing are not alaways what they seem"
    end # should call each encoder starting with the last
  end # .dump
  
  describe "Chain" do
    it "should provide a url parameter version of itself" do
      chain  = Yaram::Encoder::Chain.new(Yaram::GenericEncoder, Yaram::GzipEncoder, Yaram::BzipEncoder)
      chain.as_urlparam.should == "encoder=yaram:ox:%20%20%20,yaram:gzip:%20,yaram:bzip:%20"
    end # should provide a url parameter version of itself
    it "should be constructable from a urlparam" do
      chain = Yaram::Encoder::Chain.from_urlparam("encoder=#{Yaram::GenericEncoder.prefix},#{Yaram::GzipEncoder.prefix},#{Yaram::BzipEncoder.prefix}")
      chain.should be_a Yaram::Encoder::Chain
      chain[0].should be_a(Yaram::GenericEncoder)
      chain[1].should be_a(Yaram::GzipEncoder)
      chain[2].should be_a(Yaram::BzipEncoder)
    end # should be constructable from a urlparam
  end # Chain
  
  specify "spawned actors's addresses should include encoding as url params" do
    Counter.new.extend(Yaram::Actor).spawn(:log => false).should include("?encoder=")
  end # spawned actors's addresses should include encoding as url params
end # Yaram::Encoder


