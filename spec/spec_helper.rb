require "yaram"
require 'benchmark'

module Yaram::Test

  class Actor < ::Yaram::Actor::Base
    def status
      reply(:up)
    end # status
  end # class::Actor

  class MultiReplyActor < ::Yaram::Actor::Base
    def status
      reply(:up)
      reply("incorrect response")
    end # status
  end # class::MultiReplyActor

  class Counter < ::Yaram::Actor::Base
    def initialize
      super
      @count = 0
    end # initialize
    def inc(amt)
      @count += amt
    end # inc(amt)
    def value
      reply(@count)
    end # value
  end # class::Counter < Yaram::Actor::Base
  
  module RSpec
    
  end # module::RSpec
end # module::Yaram::Test


RSpec::Matchers.define :take_less_than do |n|
  chain :seconds do; end
  match do |block|
    @elapsed = Benchmark.realtime do
      block.call
    end
    (@elapsed).tap{|t| puts "time: #{t}"} <= n
  end # |block|
  failure_message_for_should do |block|
    "expected to take less than #{n}, but it took #{@elapsed}"
  end #  |block|
  failure_message_for_should_not do |block|
    "expected to take more than #{n}, but it took #{@elapsed}"
  end #  |block|
end # |n|