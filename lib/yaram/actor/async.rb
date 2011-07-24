module Yaram
  module Actor
    # When mixed in to a class that also mixes in Actor all messages will be sent, by default, asynchronously
    module Async
      def method_missing(meth, *args)
        self.publish(Message.new([meth, *args]).to(@outbox.address))
      end 
    end # module::Async
  end # module::Actor
end # module::Yaram