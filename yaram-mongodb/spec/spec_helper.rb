require "yaram/mongodb"
require "yaram"

module Yaram::Mongodb::Test
  class MCounter
    include Yaram::Actor
    def initialize(start = 0)
      @counter = start
      # When debugging let's us know how far the object got in its processing.
      trap("TERM") do
        puts @counter
        Process.exit
      end # 
    end 
    def status
      message("retrieving status ... please wait a moment")
      message(:down)
      :up
    end # status
    def inc(amt)
      @counter += amt
    end # inc
    def value
      @counter
    end # value
    def echo(msg)
      msg
    end
    def anything(*args)
    end # anything(*args)
    def crash
      raise "I'm stupid"
    end # crash
    
  end # class::MCounter



  module RSpec
    
  end # module::RSpec
end # module::Yaram::Mongo::Test