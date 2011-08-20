require "uuid"
module Yaram
  class Mailbox
    class Fifo < Mailbox
      
      def bind(addr = nil)
        close if connected?
        addr        = (@address || "fifo:///tmp/actors/#{Process.pid}-#{UUID.generate}.fifo")  if addr.nil?
        @address    = addr
        @uri         = URI.parse(addr)
        raise ArgumentError.new("address '#{addr}' scheme must be fifo").extend(::Yaram::Error) unless @uri.scheme == "fifo"
        
        pdir = File.dirname(@uri.path)
        Dir.mkdir(pdir) unless File.exists?(pdir)
        
        mkfifo(@uri.path) unless File.exists?(@uri.path)
        
        @io      = open(@uri.path, "r+")
        @io.sync = true
        @bound   = true
        super()
      end # bind(addr = nil)

      def connect(addr = nil)
        close if bound?
        @uri = URI.parse(@address || addr)
        raise ArgumentError.new("address '#{addr}' scheme must be fifo").extend(::Yaram::Error) unless @uri.scheme == "fifo"

        mkfifo(@uri.path) unless File.exists?(@uri.path)

        @io        = open(@uri.path, "w+")
        @io.sync   = true
        @address   = addr
        @bound     = false
        @connected = true
        super()
      end # connect(addr)
      
      # Close the mailbox
      # @return [String] the address of the mailbox that was closed
      def close
        unbind.tap do
          File.delete(@uri.path) if @bound && File.exists?(@uri.path)
        end # tap
      end # close
      
    end # class::Fifo < Mailbox
  end # class::Mailbox
end # module::Yaram
