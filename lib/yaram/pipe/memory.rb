module Yaram
  class Pipe
    class Memory < Pipe

      def initialize
        super(*(eps = [*IO.pipe, *IO.pipe]))
        @ios = [ [eps[0], eps[3]], [eps[2], eps[1]] ]
      end

    end # class::Memory < Pipe
  end # class::Pipe
end # module::Yaram