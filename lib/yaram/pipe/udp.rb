require "socket"

module Yaram
  class Pipe
    class Udp < Pipe      
      
      class << self
        def port
          @port ||= 4897
        end # port
        def port=(num)
          @port = num
        end # port=(num)
      end # << self
      
      def initialize
        eps = []
        2.times do
          read_io = UDPSocket.new
          begin
            read_io.bind("0.0.0.0", self.class.port)
          rescue Errno::EADDRINUSE => e
            self.class.port += 1
            retry
          end # begin
          read_io.do_not_reverse_lookup
          write_io = UDPSocket.new
          write_io.connect("127.0.0.1", self.class.port)
          self.class.port += 1    
          eps.push(read_io)
          eps.push(write_io)
          eps.push("udp://0.0.0.0:#{read_io.addr[1]}")
        end # 2.times

        super(*[*eps[0..1], *eps[3..4]])
        @ios = [ [eps[0], eps[4], eps[2]], [eps[3], eps[1], eps[5]] ]
      end # initialize
      
      # @return
      def address
        @address
      end # address
      
    end # class::Udp < Pipe
  end # class::Pipe
end # module::Yaram