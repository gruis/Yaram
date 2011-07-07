require "yaram"

module Yaram::Test

  class Actor < ::Yaram::Actor::Base
    def status
      reply(:up)
    end # status
  end # class::Actor
  
  module RSpec
    
  end # module::RSpec
end # module::Yaram::Test