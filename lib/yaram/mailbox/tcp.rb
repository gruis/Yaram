module Yaram
  class Mailbox
    class Tcp < Mailbox
      include Ip
      include PersistentClients
      
      # @return
      def connect(addr = nil)
        close if bound?
        uri = URI.parse(@address || addr)
        raise ArgumentError.new("address '#{addr}' scheme must be tcp").extend(::Yaram::Error) unless uri.scheme == "tcp"

        pdir = File.dirname(uri.path)
        Dir.mkdir(pdir) unless File.exists?(pdir)

        @io          = TCPSocket.new(uri.host, uri.port)
        @io.nonblock = true
        @address     = addr
        super()
      end # connect
      
      
      # Bind a mailbox to recieve messages
      # @param [String] addr address in the form of a URI
      def bind(addr = nil)
        close if connected? || bound?

        addr ||= @address
        if addr.nil?
          bind_ip = "0.0.0.0"
          ip      = addresses[0]
        else
          uri     = URI.parse(addr)
          raise ArgumentError.new("address '#{addr}' scheme must be udp").extend(::Yaram::Error) unless uri.scheme == "udp"
          bind_ip = uri.host
          ip      = bind_ip == "0.0.0.0" ? addresses[0] : bind_ip
          port    = uri.port
        end # addr.nil?

        if port.nil?
          begin
            @io = TCPServer.new(bind_ip, self.class.port)
          rescue Errno::EADDRINUSE => e
            self.class.port += 1
            retry
          end # begin
        else
          begin
            @io = TCPServer.new(bind_ip, port)
          rescue Errno::EADDRINUE => e
            raise e.extend(::Yaram::Error)
          end # begin
        end # port.nil?

        @inboxes = [] 
        inboxes
        @address = "tcp://#{ip}:#{@io.addr[1]}"
        super()
      end # bind(bind_ip = nil)
      
      
      private
      
      # Check for any clients that have innitaitied a connection 
      # and add their socket connections to the list of inboxes
      # to check.
      # @return [Yaram::Mailbox::Unix] self
      def inboxes
        nomoreclients = false
        until nomoreclients
          begin
            @inboxes.push(@io.accept_nonblock.tap{|c| c.nonblock = true })
          rescue IO::WaitReadable, Errno::EINTR
            nomoreclients = true
          end # begin          
        end # nomoreclients
        @inboxes
      end # add_clients
    end # class::Tcp < Mailbox
  end # class::Mailbox
end # module::Yaram