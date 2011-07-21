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
        puts "#{Process.pid} #{self.class}#new(#{addr})"
        super(addr)
      end # initialize(addr = nil)
      
      def connect(addr = nil)
        puts "#{Process.pid} #{self.class}#connect(#{addr})"
        addr ||= @address
        close if bound? || connected?
        @io = redis_connection(addr)
        super()
      end
      
      def bind(addr = nil)
        puts "#{Process.pid} #{self.class}#bind(#{addr})"
        close if connected? || bound?
        addr ||= @address
        @io = redis_connection(addr)
        @io.write("SUBSCRIBE #{@channel}\r\n")
        super()
      end
      
      def read(bytes = 40960)
        puts "#{Process.pid} #{self.class}#read(#{bytes})"
        super.split("\n")[6..-1]
              .tap{|m| puts "#{Process.pid} #{self.class}#read - msg: #{m}"}
              .join("\n")
              .chomp
      end
      
      def write(msg)
        puts "#{Process.pid} #{self.class}#write(#{msg})"
        super("PUBLISH #{@channel} \"#{msg.gsub('"', '\"')}\"")
      end # write(msg)
      
      
      private
      
      
      def redis_connection(addr)
        puts "#{Process.pid} #{self.class}#redis_connection(#{addr})"
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
