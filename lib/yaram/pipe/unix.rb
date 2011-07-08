module Yaram
  class Pipe
    class Unix < Pipe

      def initialize
        super(*(eps = [*IO.pipe, *IO.pipe]))
        @ios = [ [eps[0], eps[3]], [eps[2], eps[1]] ]
      end

    end # class::Unix < Pipe
  end # class::Pipe
end # module::Yaram