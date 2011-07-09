require "yaram"

module Yaram::Test

  class Actor < ::Yaram::Actor::Base
    def status
      reply(:up)
    end # status
  end # class::Actor

  class MultiReplyActor < ::Yaram::Actor::Base
    def status
      reply("incorrect response")
      reply(:up)
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