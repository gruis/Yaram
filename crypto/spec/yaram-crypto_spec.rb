require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram::Crypto do
  it "should have a VERSION" do
    Yaram::Crypto.const_defined?(:VERSION).should be true
  end # it "should have a VERSION"
  describe "VERSION" do
    subject { Yaram::Crypto::VERSION }
    it { should be_a String }
  end # describe "VERSION"
  
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
end # describe YaramCrypto
