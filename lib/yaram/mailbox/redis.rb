module Yaram
  class Mailbox
    # The Redis mailbox uses a redis server as a broker and work queue.
    class Redis < Mailbox
      
      class << self
        # Allows a default host to be setup
        attr_accessor :host        
      end # << self
      
      # @return
      def initialize(addr = nil)
        super(addr)
      end # initialize(addr = nil)
      
      def connect(addr = nil)
        addr ||= @address
        close if bound? || connected?
        @io = redis_connection(addr)
        super()
      end
      
      def bind(addr = nil)
        close if connected? || bound?
        addr ||= @address
        @io = redis_connection(addr)
        @io.write("SUBSCRIBE #{@channel}\r\n")
        cmd_ok?
        super()
      end
      
      def read(bytes = 40960)
        r = super.split("\r\n")
        return nil if r.nil?      
        # kludge !!!!!
        r.join("\n")
         .split("]]>]]>") # if the record seperator ever changes in Actor we'll need to change it here too!
         .map{|m| m.strip.split("\n")[6..-1].join("\n") }
         .join("]]>]]>") << "]]>]]>"
      end
      
      def write(msg)
        super("*3\r\n$7\r\nPUBLISH\r\n$#{@channel.size}\r\n#{@channel}\r\n$#{msg.size}\r\n#{msg}\r\n")
        raise ::Yaram::CommunicationError.new("failed to send message") unless cmd_ok?
        msg.length
      end # write(msg)
      
      
      private
      
      def cmd_ok?
        begin
          result = @io.read_nonblock(40960)
        rescue IO::WaitReadable, Errno::EINTR
          IO.select([@io], nil, nil)
          retry
        end
        result.chomp[-2..-1] == ":1"
      end # cmd_ok?
      
      
      def redis_connection(addr)
        uri = URI.parse(addr)
        raise ArgumentError.new("address '#{addr}' scheme must be redis").extend(::Yaram::Error) unless uri.scheme == "redis"
        raise ArgumentError.new("address '#{addr}' must contain a path for subscription").extend(::Yaram::Error) if uri.path.nil?

        port     = uri.port || 6379
        @channel = uri.path[1..-1]
        @address = addr
        io      = TCPSocket.new(uri.host, port)
        authenticate(uri) if uri.user && uri.password
        io
      end # redis_connection(addr)
      
      
      def authenticate(uri)
        raise NotImplementedError
      end 
      
    end # class::Redis < Mailbox
  end # class::Mqilbox
end # module::Yaram
