require "socket"
module Yaram
  class Mailbox
    module Ip
      
      # @return
      def self.included(c)
        c.extend(ClassMethods)
      end # self.included(c)
      
      
      # Determine the ip addresses assigned to this machine
      # @return [[String]] array of ip addresses for this machine 
      def addresses(ipv = 4)
        type = ([6, "AF_INET6"].include?(ipv)) ? "AF_INET6" : "AF_INET"
        Socket.getaddrinfo(Socket.gethostname, nil, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)
          .select{|sock| sock[0] == type }
          .map{|sock| sock[3] }
      end # addresses
      
      module ClassMethods
        def port
          @port ||= 4897
        end # port
        
        def port=(num)
          @port = num
        end # port=(num)
      end # module::ClassMethods
      
    end # module::Ip
  end # class::Mailbox
end # module::Yaram