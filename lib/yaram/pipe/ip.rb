require "socket"
module Yaram
  class Pipe
    module Ip
      # Determine the ip addresses assigned to this machine
      # @return [[String]] array of ip addresses for this machine 
      def addresses(ipv = 4)
        type = ([6, "AF_INET6"].include?(ipv)) ? "AF_INET6" : "AF_INET"
        Socket.getaddrinfo(Socket.gethostname, nil, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)
          .select{|sock| sock[0] == type }
          .map{|sock| sock[3] }
      end # addresses
    end # module::Ip
  end # class::Pipe
end # module::Yaram