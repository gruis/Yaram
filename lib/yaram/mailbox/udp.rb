module Yaram
  class Mailbox
    class Udp < Mailbox
      include Pipe::Ip
      
      class << self
        def port
          @port ||= 4897
        end # port
        
        def port=(num)
          @port = num
        end # port=(num)
      end # << self

      # Bind a mailbox to recieve messages
      # @param [String] addr address in the form of a URI
      def bind(addr = nil)
        if !addr.nil?
          bind_ip = "0.0.0.0"
          ip = addresses[0]
        else
          uri = URI.parse(addr)
          raise ArgumentError.new("address '#{addr}' scheme must be udp").extend(::Yaram::Error) unless uri.scheme == "udp"
          bind_ip      = uri.host
          port         = uri.port
        end # addr.nil?
        
        if bind_ip.nil?
          bind_ip = "0.0.0.0"
          ip = addresses[0]
        else
          ip = bind_ip
        end # bind_ip.nil?

        @io = UDPSocket.new

        if port.nil?
          begin
            @io.bind(bind_ip, self.class.port)
          rescue Errno::EADDRINUSE => e
            self.class.port += 1
            retry
          end # begin
        else
          begin
            @io.bind(bind_ip, port)
          rescue Errno::EADDRINUE => e
            raise e.extend(::Yaram::Error)
          end # begin
        end # port.nil?
        
        @address = "udp://#{ip}:#{@io.addr[1]}"
        prepare
        self
      end # bind(bind_ip = nil)
      
      def connect(addr)
        uri = URI.parse(addr)
        raise ArgumentError.new("address '#{addr}' scheme must be udp").extend(::Yaram::Error) unless uri.scheme == "udp"
        bind_ip  = uri.host
        port     = uri.port

        @address = addr
        @io      = UDPSocket.new
        @io.connect(uri.host, uri.port)
        self
      end # connect(addr)
      
      
    end # class::Udp
  end # class::Mailbox
end # module::Yaram
