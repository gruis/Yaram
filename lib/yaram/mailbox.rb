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
          raise ArgumentError.new("mailbox '#{type}' type not found").extend(Error) unless const_defined?(type, false)
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
      
      # Inheriting classes are included in Yaram::Mailbox namespace so that build can find them easily.
      # @todo updated .build and .inherited to store inheritors in a single variable, e.g.,. Hash.
      def inherited(c)
        con = c.name.split("::").reverse.find{|p| p != "Mailbox" }
        raise ConfigurationError("Couldn't determine a mailbox class name from #{c}") if con.nil?
        con = con.to_sym
        #raise ConfigurationError("Yaram::Mailbox::#{c} has already been set") if const_defined?(con)
        return if const_defined?(con, false)
        const_set(con, c)
      end # inherited(c)
    end # << self
    
    
    attr_reader :address, :io
    
    # Create a new mailbox that can either be turned into an inbox or an outbox via bind, or connect.
    # @see #bind
    # @see #bound?
    # @see #connect
    # @see #connected?
    def initialize(addr = nil)
      @address = addr if addr.is_a?(String)
    end # initialize(addr = nil)
    
    # Bind the mailbox so that it can receive messages.
    # @return [Mailbox]
    def bind
      Yaram::Mailbox.prepare(@io)
      @connected , @bound = false, true
      self
    end # bind
    
    # A mailbox is bound if it is an inbox - one that will receive messages.
    # @return [Boolean]
    def bound?
      @bound == true
    end # bound?
    
    # Connect to another mailbox in preparation for sending messages.
    # @return [Mailbox]
    def connect
      Yaram::Mailbox.prepare(@io)
      @connected , @bound = true, false
      self
    end # connect
    
    # A mailbox is connected if it is an outbox - one that will send messages to another
    # mailbox that will receive it.
    # @return [Boolean]
    def connected?
      @connected == true
    end # connected?
    
    # Sends messages out of the mailbox and into the associated inbox.
    # @param [String] msg the message to send
    def write(msg)
      begin
        #@io.write_nonblock(msg)
        write_unblocked(@io, msg)
      rescue IO::WaitWritable, Errno::EINTR
        IO.select(nil, [@io])
        retry
      end
    end # write(msg)
    
    # Receives messages from the mailbox; expects the mailbox to be bound.
    # @param [Fixnum] bytes the maximum number of bytes to read from the inbox.
    def read(bytes = 65536)
      begin
        result = @io.read_nonblock(bytes)
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([@io], nil, nil)
        retry
      end
    end # read(bytes)
    
    # Unbinds the mailbox. 
    # Subclases should override close and add in anything necessary to cleanup the mailbox from
    # the system, e.g., delete a file.
    # @return [String] the address of the mailbox that was closed
    def close
      unbind
    end
    
    # The address of the mailbox
    def to_s
      @address || super
    end # to_s
    
    def select(timeout = 1)
      IO.select([@io], nil, nil, timeout)
    end
    
    # Close the mailbox and don't receive any messages from it
    # @return [String] the address of the mailbox
    def unbind
      @io.close
      @address.tap{ @address = "" }
    end # unbind
    
    def to_io
      @io
    end # to_io
    
    def prepare
      Yaram::Mailblox.prepare(@io)
    end # prepare

  end # class::Mailbox
end # module::Yaram