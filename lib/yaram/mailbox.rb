require "uri"
require "yaram/mailbox/udp"
require "yaram/mailbox/fifo"

module Yaram
  class Mailbox
    
    
    class << self      
      # Prepare IOs for use as a Mailbox
      # @return [IO]
      def prepare(*ios)
        ios.each do |io|
          if defined? Fcntl::F_GETFL
            io.fcntl(Fcntl::F_SETFL, io.fcntl(Fcntl::F_GETFL) | Fcntl::O_NONBLOCK)
          else
            io.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
          end # defined? Fcntl::F_GETFL
        end # do  |io|
        ios.length == 1 ? ios[0] : ios
      end # prepare(*ios)
    end # << self
    
    
    attr_reader :address, :io
    
    # Bind the mailbox so that it can receive messages
    # @return
    def bind
      raise NotImplementedError
    end # bind
    
    # Connect to another mailbox in preparation for sending messages
    # @return
    def connect
      raise NotImplementedError
    end # connect
    
    def write(msg)
      begin
        result = @io.write_nonblock(msg)
      rescue IO::WaitWritable, Errno::EINTR
        IO.select(nil, [@io])
        retry
      end
    end # write(msg)
    
    def read(bytes = 4096)
      @io.readpartial(bytes)
    end # read(bytes)

    def select(timeout = 1)
      IO.select([@io], nil, nil, timeout)
    end
    
    def close
      @io.close
    end
    
    def to_io
      @io
    end # to_io
    
    def prepare
      Yaram::Mailblox.prepare(@io)
    end # prepare

  end # class::Mailbox
end # module::Yaram