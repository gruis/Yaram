require "uri"
require "io/nonblock"
require "yaram/mailbox/ip"
require "yaram/mailbox/persistent_clients"
require "yaram/mailbox/udp"
require "yaram/mailbox/fifo"
require "yaram/mailbox/tcp"
require "yaram/mailbox/unix"
require "yaram/mailbox/redis"

module Yaram
  class Mailbox
    
    
    class << self      
      # Prepare IOs for use as a Mailbox
      # @return [IO]
      def prepare(*ios)
        ios.each { |io| io.nonblock = true }
        ios.length == 1 ? ios[0] : ios
      end # prepare(*ios)

      def build(mbox = nil)
        case mbox
        when nil then Yaram::Mailbox::Fifo.new
        when Yaram::Mailbox then mbox
        when Class
          raise ArgumentError, "mailbox '#{mbox}' must inherit from Yaram::Mailbox" unless mbox < Yaram::Mailbox
          mbox.new
        when String
          uri     = URI.parse(mbox)
          type    = uri.scheme.capitalize
          raise ArgumentError.new("mailbox '#{type}' type not found").extend(Error) unless const_defined?(type)
          const_get(type).new(mbox)
        else
          raise ArgumentError, "mailbox '#{mbox}' is not a recognized Yaram::Mailbox, or Yaram::Mailbox class"
        end # case pipe
      end # build
      
      # Create a Mailbox connected to the given address
      # @return
      def connect(addr)
        build(addr).connect(addr)
      end # connect(addr)
      
    end # << self
    
    
    attr_reader :address, :io
    
    # Create a new mailbox
    # @return
    def initialize(addr = nil)
      @address = addr if addr.is_a?(String)
    end # initialize(addr = nil)
    
    # @return
    def to_s
      @address || super
    end # to_s
    
    # Bind the mailbox so that it can receive messages
    # @return
    def bind
      Yaram::Mailbox.prepare(@io)
      @connected , @bound = false, true
      self
    end # bind
    
    # Connect to another mailbox in preparation for sending messages
    # @return
    def connect
      Yaram::Mailbox.prepare(@io)
      @connected , @bound = true, false
      self
    end # connect
    
    def write(msg)
      puts "#{Process.pid} #{self.class}#write(#{msg})"
      begin
        #@io.write_nonblock(msg)
        write_unblocked(@io, msg)
      rescue IO::WaitWritable, Errno::EINTR
        IO.select(nil, [@io])
        retry
      end
    end # write(msg)
    
    def read(bytes = 40960)
      begin
        result = @io.read_nonblock(bytes)
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([@io], nil, nil)
        retry
      end
    end # read(bytes)
    
    def select(timeout = 1)
      IO.select([@io], nil, nil, timeout)
    end
    
    # Unbinds the mailbox. 
    # Subclases should override close and add in anything necessary to cleanup the mailbox from 
    # the system, e.g., delete a file.
    # @return [String] the address of the mailbox that was closed
    def close
      unbind
    end
    
    # Close the mailbox and don't receive any messages from it
    # @return
    def unbind
      @io.close
      @address.tap{ @address = "" }
    end # unbind
    
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