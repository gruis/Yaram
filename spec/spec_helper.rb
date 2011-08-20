require "yaram"
require 'benchmark'
require "timeout"

module Yaram::Test
  class << self
    def redis_up?(host = "127.0.0.1", port = 6379)
      sock    = nil
      begin
        Timeout.timeout(1) {  sock  = TCPSocket::new(host, port) }
      rescue Timeout::Error => e
        return false
      rescue Errno::ECONNREFUSED => e
        return false
      rescue Errno::EHOSTDOWN => e
        return false
      ensure
        sock.close if sock.respond_to?(:close)
      end # begin
      true
    end # redis_up?(host = "127.0.0.1", port = 6379)
  end # class::<< self
  
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


  class Suicidal < Yaram::Actor::Base
    def die
      Process.exit
    end
    def status
      :up
    end
  end # class::Suicidal < Yaram::Actor::Base

  class Actor < ::Yaram::Actor::Base
    def status
      reply(:up)
    end # status
  end # class::Actor

  class MultiReplyActor < ::Yaram::Actor::Base
    def status
      1000.times { message("incorrect response") }
      message("incorrect response")
      :up
    end # status
  end # class::MultiReplyActor
  class ExplicitReplyActor < ::Yaram::Actor::Base
    def status
      reply(:explicit)
      :implicit
    end # status
  end # class::ExplicitReplyActor < ::Yaram::Actor::Base
  class ImplicitReplyActor < ::Yaram::Actor::Base
    def status
      :implicit
    end # status
  end # class::ImplicitReplyActor < ::Yaram::Actor::Base

  class Counter < ::Yaram::Actor::Base
    def initialize(cnt = 0)
      super
      @count = cnt
    end # initialize
    def inc(amt)
      @count += amt
    end # inc(amt)
    def value
      @count
    end # value
    def status
      :up
    end # status
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