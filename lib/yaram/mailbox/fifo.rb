require "uuid"
module Yaram
  class Mailbox
    class Fifo < Mailbox
      
      def bind(addr = nil)
        addr        = "fifo:///tmp/actors/#{Process.pid}-#{UUID.generate}.fifo"  if addr.nil?
        @address    = addr
        uri         = URI.parse(addr)
        raise ArgumentError.new("address '#{addr}' scheme must be fifo").extend(::Yaram::Error) unless uri.scheme == "fifo"
        
        pdir = File.dirname(uri.path)
        Dir.mkdir(pdir) unless File.exists?(pdir)
        system("mkfifo #{uri.path}") unless File.exists?(uri.path)
        @io      = open(uri.path, "r+")
        @io.sync = true
        @bound   = true
        self
      end # bind(addr = nil)

      def connect(addr)
        uri = URI.parse(addr)
        raise ArgumentError.new("address '#{addr}' scheme must be fifo").extend(::Yaram::Error) unless uri.scheme == "fifo"
        raise ArgumentError.new("fifo '#{uri.path}' does not exist") unless File.exist?(uri.path)

        @io      = open(uri.path, "w+")
        @io.sync = true
        @address = addr
        self
      end # connect(addr)
      
      def close
        super
        File.delete(URI.parse(@address).path) if @bound
      end # close
      
    end # class::Fifo < Mailbox
  end # class::Mailbox
end # module::Yaram
