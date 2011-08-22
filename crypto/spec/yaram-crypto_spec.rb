require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram::Crypto do
  it "should have a VERSION" do
    Yaram::Crypto.const_defined?(:VERSION).should be true
  end # it "should have a VERSION"
  describe "VERSION" do
    subject { Yaram::Crypto::VERSION }
    it { should be_a String }
  end # describe "VERSION"
end # describe YaramCrypto
