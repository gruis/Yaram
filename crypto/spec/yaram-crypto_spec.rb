require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram::Crypto do
  it "should have a VERSION" do
    Yaram::Crypto.const_defined?(:VERSION).should be true
  end # it "should have a VERSION"
  describe "VERSION" do
    subject { Yaram::Crypto::VERSION }
    it { should be_a String }
  end # describe "VERSION"
  subject { Yaram::Crypto }
  
  it { should respond_to(:genkey) }
  it { should respond_to(:keygen) }
  
  describe ".genkey" do
    it "should only generate 128, 192, or 256 bit keys" do
      expect { Yaram::Crypto.keygen(64) }.to raise_error(ArgumentError)
      expect { Yaram::Crypto.keygen(32) }.to raise_error(ArgumentError)
      expect { Yaram::Crypto.keygen(28) }.to raise_error(ArgumentError)
      expect { Yaram::Crypto.keygen(128) }.to_not raise_error(ArgumentError)
      expect { Yaram::Crypto.keygen(192) }.to_not raise_error(ArgumentError)
      expect { Yaram::Crypto.keygen(256) }.to_not raise_error(ArgumentError)
    end # should only generate 128, 192, or 256 bit keys
  end # .genkey
  
  describe "encoder" do
    before :all do
      Yaram::Crypto.setup(Yaram::Crypto.keygen(256), :string)
    end # 
    
    it "should encode and decode objects" do
      msg = Yaram::Message.new("this is a super secret message")
      (enc = Yaram::Crypto.dump(msg)).should_not == msg
      expect { m = Yaram::Crypto.load(enc) }.to_not raise_error(Yaram::EncodingError)
      Yaram::Crypto.load(enc).should be_a(Yaram::Message)
      Yaram::Crypto.load(enc).content.should == msg.content
    end # should encode and decode objects
    
    it "should produce messages that the default Yaram encoder can deal with" do
      msg = Yaram::Message.new("this is a super secret message")
      enc = Yaram::Crypto.dump(msg)
      expect { Yaram::Crypto.encoder.load(enc) }.to raise_error(Yaram::EncodingError)
      begin
        Yaram::Crypto.encoder.load(enc)
      rescue Yaram::EncodingError => e
        e.message.should == "yaram:crypt:"
      end # begin
      
    end # should produce messages that the default Yaram encoder can deal with
  end # encoder
end # describe YaramCrypto
