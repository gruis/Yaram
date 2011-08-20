require File.join(File.dirname(__FILE__), "spec_helper")

describe Yaram do
  describe "performance" do
    before(:each) { @counter = Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Udp)) }
    [100, 1000, 10000, 100000, 1000000].each do |cnt|
      it "should support #{cnt} requests" do
        cnt.times { @counter.!(:inc, 1) } 
        @counter.sync(:value).should == cnt
      end # it should support #{}
    end #  |cnt|

    it "should execute 98,500 requests per second" do
      expect {
        98500.times {  @counter.publish([:inc, 1])  }
        #
        # 99900.times do
        #   begin
        #     raise ArgumentError.new("blah")
        #   rescue Exception => e
        #     @counter.publish([:anything, e])  
        #   end # begin
        # end
        #
        #162000.times {  @counter.publish([:inc, 1])  }
      }.to take_less_than(1.0).seconds
    end # it should take less than x seconds

    describe "performance compared to non-actors" do
      nactor = Yaram::Test::Counter.new
      start = Time.new
      175000.times { nactor.inc(1) }
      duration = Time.new - start
      acceptable_multiplier = 73.5
      acceptable_speed = duration * acceptable_multiplier
      it "should execute 175,000 ops no more than #{acceptable_multiplier} times slower (#{acceptable_speed}) than a non-actor (#{duration})" do
        expect {
          175000.times { @counter.!(:inc, 1) } 
        }.to take_less_than(acceptable_speed).seconds      
      end # should execute 175,000 ops no more than 71 times slower (#{duration * 71}) than a non-actor (#{duration})      
    end # "performance compared to non-actors"
    
    it "should execute 140,000 requests per second over Udp" do
      begin
        Yaram::Actor::Proxy.new(Yaram::Test::MCounter.new.spawn(:log => false, :mailbox => Yaram::Mailbox::Udp))
        expect {
          140000.times { counter.!(:inc, 1) } 
        }.to take_less_than(1.0).seconds        
      ensure
        counter.stop
      end # begin
    end # it should take less than x seconds      
  end # "performance"
end # describe Yaram
