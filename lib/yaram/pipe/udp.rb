require "socket"

module Yaram
  class Pipe
    class Udp
      
      class << self
        # @todo support remote ip address
        def pipe
          port    = 4913
          read_io = UDPSocket.new
          begin
            read_io.bind("127.0.0.1", port)
          rescue Errno::EADDRINUSE => e
            port += 1
            retry
          end # begin
          read_io.do_not_reverse_lookup
          write_io = UDPSocket.new
          write_io.connect("127.0.0.1", port)
          [read_io, write_io]
        end # pipe
      end # << self 
           
    end # class::Udp
  end # class::Pipe
end # module::Yaram
