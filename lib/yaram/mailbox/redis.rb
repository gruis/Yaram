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
        @buffer = StringIO.new
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
        cmd_ok?(::Yaram::CommunicationError)
        super()
      end
      
      def read(bytes = 524288)
        # default bytes is high to cope with redis giving us
        # large messages. once the redis parser is written
        # bytes should be reduced.
        r = super(bytes)
        return nil if r.nil?
        messages(r).join("\n")
      end
      
      def write(msg)
        super("*3\r\n$7\r\nPUBLISH\r\n$#{@channel.size}\r\n#{@channel}\r\n$#{msg.size}\r\n#{msg}\r\n")
        # Checking the response adds significant time (~19x) for each write operation
        # cmd_ok?(::Yaram::CommunicationError)
        msg.length
      end # write(msg)
      
      
      private
      
      # Any incomplete messages will be held and appended to on subsequent calls.
      # @param [String] raw the raw redis messages
      # @return [Array]
      def messages(raw)
        @buffer.write(raw)
        @buffer.pos   = 0
        truncated_msg = nil
        msgs          = []

        rollback_pos = catch :truncated do
          # This is not pretty code.
          # I've tried to keep the number of blocks and method calls low.
          while !@buffer.eof?
            msg_start = @buffer.pos
            case @buffer.read(1)
            when "-"
              bmsg = ""
              @buffer.pos = @buffer.pos.tap{ @buffer.pos = msg_start; bmsg += @buffer.read }
              raise ::Yaram::CommunicationError, "redis message was not received correctly: #{bmsg}"
            when "*"
              # get the argument count
              cnt = ""
              throw(:truncated, msg_start) if @buffer.eof?
              true while ( cnt << @buffer.read(1) )[-2..-1] != "\r\n" && !@buffer.eof?
              throw(:truncated, msg_start) if @buffer.eof?
              cnt = cnt[0..-3]
              raise ParseError, "expected count '#{cnt}' to be 3" unless cnt == '3'
              
              # get the type
              len = ""
              true while ( ( len << @buffer.read(1) )[-2..-1] != "\r\n" && !@buffer.eof?)
              throw(:truncated, msg_start) if @buffer.eof?
              raise ParseError, "expected first argument length '#{len[1..-3]}' to be 7" unless '7' == len[1..-3]
              type = @buffer.read(7)
              @buffer.read(2) # pull off the CRLF
              throw(:truncated, msg_start) if @buffer.eof?
              raise ParseError, "expected type '#{type}' to be 'message'" unless 'message' == type
              
              # get the topic
              len = ""
              true while ( ( len << @buffer.read(1) )[-2..-1] != "\r\n" && !@buffer.eof?)
              throw(:truncated, msg_start) if @buffer.eof?
              len   = len[1..-3].to_i
              topic = @buffer.read(len)
              @buffer.read(2) # pull off the CRLF
              throw(:truncated, msg_start) if @buffer.eof?
              
              # get the message
              len = ""
              true while ( ( len << @buffer.read(1) )[-2..-1] != "\r\n" && !@buffer.eof?)
              throw(:truncated, msg_start) if @buffer.eof?
              len = len[1..-3].to_i
              msg = @buffer.read(len)
              throw(:truncated, msg_start) if len != msg.length && @buffer.eof?
              msgs.push(msg)
              @buffer.read(2) # pull off the CRLF
            when ""
              # we're at the end of the buffer
              raise ParseError, "expected to be at the end of the buffer" unless @buffer.eof?
            end # !@buffer.eof?
          end # io.pos != io.length
        end # :truncated

        if rollback_pos.nil?
          @buffer.truncate(0)
        else
          @buffer.pos = rollback_pos
          contents = @buffer.read
          @buffer.truncate(0)
          @buffer.write(contents)
        end # rollback_pos.nil?
        
        msgs
      end # messages(raw)
      
      
      # Check for a success code response from the redis server
      # @param [Exception, nil] excp the exception class to raise on error, or nil
      # @return [true, false]
      def cmd_ok?(excp)
        begin
          result = @io.read_nonblock(65536)
        rescue IO::WaitReadable, Errno::EINTR
          IO.select([@io], nil, nil)
          retry
        end
        result.chomp!
        if result[0] == "-"
          raise excp.new("redis command failed: #{result}") unless excp.nil?
          return false
        end
        true
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
