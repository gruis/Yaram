require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do
  describe "performance" do
    before(:each) { @counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false) }
    after(:each) { @counter.stop }
    [100, 1000, 10000, 100000, 1000000].each do |cnt|
      it "should support #{cnt} requests" do
        cnt.times { @counter.recover(1) { @counter.!(:inc, 1) } }
        @counter.sync(:value).should == cnt
      end # it should support #{}
    end #  |cnt|

    it "should execute 175,000 requests per second" do
      expect {
        175000.times { @counter.recover(1) { @counter.!(:inc, 1) } }
        #175000.times { @counter.publish(Yaram::Message.new([:inc, 1])) }
      }.to take_less_than(1.0).seconds
    end # it should take less than x seconds  

    it "should execute 140,000 requests per second over Udp" do
      begin
        counter = Yaram::Actor::Simple.new(Yaram::Test::Counter, :log => false, :pipe => Yaram::Pipe::Udp.new)
        expect {
          140000.times { counter.recover(1) { counter.!(:inc, 1) } }
        }.to take_less_than(1.0).seconds        
      ensure
        counter.stop
      end # begin
    end # it should take less than x seconds      
  end # "performance"
  
end # describe Yaram
