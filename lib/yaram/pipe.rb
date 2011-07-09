require "yaram/pipe/unix"
require "yaram/pipe/udp"
require "yaram/pipe/tcp"

module Yaram
  class Pipe
    
    def initialize(*ios)
      ios.each do |io|
        if defined? Fcntl::F_GETFL
          io.fcntl(Fcntl::F_SETFL, io.fcntl(Fcntl::F_GETFL) | Fcntl::O_NONBLOCK)
        else
          io.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
        end # defined? Fcntl::F_GETFL
      end # do  |io|
    end # initialize(*fds)

    def connect(side = :actor)
      raise StartError, "constructor for #{self.class} did not set @ios" unless @ios.is_a?(Array)
      raise StartError, "#{self}#connect cannot be called twice" if :already_called == @ios
      @read_io, @write_io = (:client == side ? @ios.pop : @ios.shift)
      @ios.shift.each { |io| io.close }
      @ios = :already_called
    end
    
    def readpartial(bytes = 4096)
      @read_io.readpartial(4096)
    end
    
    def write(msg)
      @write_io.write(msg)
    end
    
    def select(timeout = 1)
      IO.select([@read_io], nil, nil, timeout)
    end
    
    def close
      @read_io.close if @read_io.respond_to?(:close)
      @write_io.close if @read_io.respond_to?(:close)
    end
    
    class << self
      # Creates a pipe or returns one that is provided.
      # @param [Class, Yaram::Pipe, nil] pipe if Class then it will be instantiated; if an  instance of Yaram::Pipe then
      #                                       pipe will be returned; if nil then a Yaram::Pipe::Unix will be returned
      # @return [Yaram::Pipe]
      # @raise [ArgumentError] if Class does not inherit from Yaram::Pipe, or if pipe is not a Yaram::Pipe or nil
      def make_pipe(pipe = nil)
        case pipe
        when nil then Yaram::Pipe::Unix.new
        when Yaram::Pipe then pipe
        when Class
          raise ArgumentError, "pipe '#{pipe}' must inherit from Yaram::Pipe" unless pipe < Yaram::Pipe
          pipe.new
        else
          raise ArgumentError "pipe '#{pipe}' is not a recognized Yaram::Pipe, or Yaram::Pipe class"
        end # case pipe
      end # make_pipe
    end # << self
    
  end # class::Pipe
end # module::Yaram