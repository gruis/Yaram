module Yaram
  module Actor
    class Proxy
      include Yaram::Actor
      
      attr_reader :outbox
      
      # Creates a connection to an actor allowing method calls
      # to the Proxy to be passed to the actor.
      # @param [String] addr the address of the actor
      # @todo support custom encoder chains
      def initialize(addr)
        @connections ||= Hash.new {|hash,key| hash[key] = Mailbox.connect(key) }
        @connections[addr] = Mailbox.connect(addr)
        @outbox            = @connections[addr]

        uri                = URI.parse(addr)
        if uri.scheme == "redis"
          uri.path = "/#{UUID.generate}"
          @inbox             = @connections[addr].class.new(uri.to_s).bind
        else
          @inbox             = @connections[addr].class.new.bind
        end # addr.scheme == "redis"        

        @address           = @inbox.address
        @def_to            = []
        @def_context       = []

        @msgs = Hash.new {|hash,k| hash[k] = [] }
        @lock = Mutex.new
      end # initialize(addr)

      # Call a method on the actor asynchronously
      # @param [Symbol] meth the method to call
      # @param [Object(s)] the arguments to provide to the method
      def !(meth, *args)
        publish([meth, *args])
      end 

      # Call a method on the actor and return its reply
      # @param [Symbol] meth the method to call
      # @param [Object(s)] the arguments to provide to the method
      def sync(meth, *args)
        request([meth, *args])
      end
      
      # Send a message and wait for a reply.
      def request(msg, opts = {})
        m = msg.is_a?(Message) ? msg : Message.new(msg)
        super(m.to(@outbox.address), opts)
      end # request(msg)
      
      # Send a message asynchronously
      def publish(msg)
        m = msg.is_a?(Message) ? msg : Message.new(msg)
        super(m.to(@outbox.address))
      end # publish(msg)
      
    end # class::Proxy
  end # module::Actor
end # module::Yaram
