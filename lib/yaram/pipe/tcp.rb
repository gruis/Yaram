require "socket"
require "yaram/pipe/ip"

module Yaram
  class Pipe
    class Tcp < Pipe
      include Ip
      class << self
        def port
          @port ||= 4897
        end # port
        def port=(num)
          @port = num
        end # port=(num)
      end # << self
      
      def initialize
        raise NotImplementedError
        eps = []
        2.times do
          begin
            read_io = TCPServer.new("127.0.0.1", self.class.port)
          rescue Errno::EADDRINUSE => e
            self.class.port += 1
            retry
          end # begin
          read_io.do_not_reverse_lookup
          write_io = TCPSocket.new("127.0.0.1", self.class.port)
          self.class.port += 1    
          eps.push(read_io)
          eps.push(write_io)
        end # 2.times

        super(*eps)
        @ios = [ [eps[0], eps[3]], [eps[2], eps[1]] ]
      end # initialize
    end # class::Tcp < Pipe
  end # class::Pipe
end # module::Yaram
