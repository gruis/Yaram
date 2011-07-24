module Yaram
  module Actor
    # When mixed in to a class that also mixes in Actor all messages will be sent, by default, synchronously
    module Sync
      def method_missing(meth, *args)
        self.request(Message.new([meth, *args]).to(@outbox.address))
      end
    end # module::Sync
  end # module::Actor
end # module::Yaram