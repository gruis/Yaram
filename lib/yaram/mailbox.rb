require "uri"
require "yaram/mailbox/udp"
require "yaram/mailbox/fifo"
require "yaram/mailbox/tcp"
require "yaram/mailbox/unix"

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

      def build(mbox = nil)
        case mbox
        when nil then Yaram::Mailbox::Udp.new
        when Yaram::Mailbox then mbox
        when Class
          raise ArgumentError, "mailbox '#{mbox}' must inherit from Yaram::Mailbox" unless mbox < Yaram::Mailbox
          mbox.new
        else
          raise ArgumentError "mailbox '#{mbox}' is not a recognized Yaram::Mailbox, or Yaram::Mailbox class"
        end # case pipe
      end # build
    end # << self
    
    
    attr_reader :address, :io
    
    # Bind the mailbox so that it can receive messages
    # @return
    def bind
      Yaram::Mailbox.prepare(@io)
      @bound = true
      self
    end # bind
    
    # Connect to another mailbox in preparation for sending messages
    # @return
    def connect
      Yaram::Mailbox.prepare(@io)
      @connected = true
      self
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
    
    def bound?
      @bound == true
    end # bound?
    
    # @return
    def connected?
      @connected == true
    end # connected?
    
    def prepare
      Yaram::Mailblox.prepare(@io)
    end # prepare

  end # class::Mailbox
end # module::Yaram