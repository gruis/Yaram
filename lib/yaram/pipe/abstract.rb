module Yaram
  class Pipe
    READER = 0
    WRITER = 1

    class << self
      def open(type = :memory)
        @classes ||= { }
        raise ArgumentError, "'#{type}' is not a registered pipe type" if @classes[type].nil?
        @classes[type].open
      end # open
      def register(c)
        (@classes ||= { })["#{c}".split("Yaram::Pipe",2)[-1].downcase.gsub("::", "-")] = c
      end # inherited(c)
    end # << self

      
    class Abstract

      class << self
        def inherited(c)
          Yaram::Pipe.register(c)
        end # inherited(c)

        # Open both sides of a pipe
        # @return [[pipe, pipe]]
        def open
          [new("", "r"), new("", "w")]
        end # open
      end # << self


      def initialize(path, mode)
        @path = path
        @mode = mode == "w" ? Pipe::WRITER : Pipe::READER
      end # initialize(path, mode)


      def fcntl(op, mask)
        raise NotImplementedError
      end # fcntl
      
      # @return
      def close
        raise NotImplementedError
      end # close
      
      def write
        raise IOError, "not opened for writing" unless WRITER == @mode 
      end # write
      
      # @return
      def read
        raise IOError, "no opened for reading" unless READER == @mode
      end # read
      
      # @return
      def readpartial(bytes)
        raise NotImplementedError
      end # readpartial(bytes)
      
    end # class::Abstract    
  end # class::Pipe
end # module::Yaram