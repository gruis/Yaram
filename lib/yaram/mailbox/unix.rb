require "socket"

module Yaram
  class Mailbox
    class Unix < Mailbox
      
      # @return
      def connect(addr = nil)
        close if bound?
        uri = URI.parse(@address || addr)
        raise ArgumentError.new("address '#{addr}' scheme must be unix").extend(::Yaram::Error) unless uri.scheme == "unix"

        pdir = File.dirname(uri.path)
        Dir.mkdir(pdir) unless File.exists?(pdir)

        @io  = UNIXSocket.new(uri.path)

        @address   = addr
        super()
      end # connect
      
      
      def bind(addr = nil)
        close if connected?
        addr        = (@address || "unix:///tmp/actors/#{Process.pid}-#{UUID.generate}.uds")  if addr.nil?
        @address    = addr
        uri         = URI.parse(addr)
        raise ArgumentError.new("address '#{addr}' scheme must be unix").extend(::Yaram::Error) unless uri.scheme == "unix"
        
        pdir = File.dirname(uri.path)
        Dir.mkdir(pdir) unless File.exists?(pdir)

        @inboxes = []        
        @io      = @socket = UNIXServer.new(uri.path)
        
        super()
        inboxes
        self
      end # bind(bind_ip = nil)

      # Send a message to an inbox
      def write(msg)
        begin
          @io.send(msg, 0)
        rescue IO::WaitWritable, Errno::EINTR
          IO.select(nil, [@io])
          retry
        end
      end # write(msg)

      # Read a message from the first client connection that has sent data
      # @todo round-robin between the clients.
      def read(bytes = 40960)
        begin
          IO.select(@inboxes, nil, nil)[0][0].recv(bytes)
        rescue IO::WaitReadable, Errno::EINTR
          IO.select([@inboxes], nil, nil)
          retry
        end
        #@io.readpartial(bytes)
      end # read(bytes)
      
      def select(timeout = 1)
        @bound ? IO.select(inboxes, nil, nil, timeout) : IO.select(nil, [@io], nil, timeout)
      end
      
      # @return [String] address
      def close
        @inboxes.each{|i| i.close } if @bound
        path = @socket.path
        @socket.close
        File.delete(path)
        @address
      end # close
      

      private
      
      # Check for any clients that have innitaitied a connection 
      # and add their socket connections to the list of inboxes
      # to check.
      # @return [Yaram::Mailbox::Unix] self
      def inboxes
        nomoreclients = false
        until nomoreclients
          begin
            # @socket has already been unblocked so accept should behave the same as accept_nonblock
            @inboxes.push(@socket.accept_nonblock.tap{|s| s.nonblock = true; })
          rescue IO::WaitReadable, Errno::EINTR
            nomoreclients = true
          end # begin          
        end # nomoreclients
        @inboxes
      end # add_clients
      
      
    end # class::Unix < Mailbox
  end # class::Mailbox
end # module::Yaram
