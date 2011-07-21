module Yaram
  module Actor
    class Proxy      
      include Yaram::Actor      

      attr_reader :outbox

      def initialize(addr)
        @connections ||= Hash.new {|hash,key| hash[key] = Mailbox.connect(key) }
        @connections[addr] = Mailbox.connect(addr)
        @outbox            = @connections[addr]

        uri                = URI.parse(addr)
        if uri.scheme == "redis"
          puts "#{Process.pid}#{self.class}#new - scheme: redis; uri: #{uri}"
          uri.path = "/#{UUID.generate}"
          puts "#{Process.pid}#{self.class}#new - uri: #{uri}"
          @inbox             = @connections[addr].class.new(uri.to_s).bind
        else
          @inbox             = @connections[addr].class.new.bind
        end # addr.scheme == "redis"        

        @address           = @inbox.address
        @def_to            = []
        @def_context       = []

        @msgs = Hash.new {|hash,k| hash[k] = [] }        
        @lock = Mutex.new
        #@msgcache ||= {}#Hash.new {|h,k| h[k] = Yaram.encoder.dump(k) }
        #puts "#{Process.pid} #{self.class}.new(#{addr})"
        #puts "#{Process.pid}  outbox: #{@outbox}"
        #puts "#{Process.pid}  inbox:  #{@inbox}"
      end # initialize(addr)
      
      def request(msg)
        m = msg.is_a?(Message) ? msg : Message.new(msg)
        super(m.to(@outbox.address))
      end # request(msg)
      
      def publish(msg)
        m = msg.is_a?(Message) ? msg : Message.new(msg)
        super(m.to(@outbox.address))
      end # publish(msg)
      
      
      # Send a message asynchronously
      def !(meth, *args)
        publish([meth, *args])
      end 

      # Send a message and wait for a reply
      def sync(meth, *args)
        request([meth, *args])
      end
    end # class::Proxy
  end # module::Actor
end # module::Yaram
