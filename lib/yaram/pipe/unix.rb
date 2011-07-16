module Yaram
  class Pipe
    class Unix < Pipe

      def initialize
        super(*(eps = [*IO.pipe, *IO.pipe]))
        @ios = [ [eps[0], eps[3]], [eps[2], eps[1]] ]
        @ios[0].push("unix://#{@ios[0][0].fileno}")
        @ios[1].push("unix://#{@ios[1][0].fileno}")
      end

    end # class::Unix < Pipe
  end # class::Pipe
end # module::Yaram