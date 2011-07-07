module Yaram
  class Pipe
    class Memory < Abstract
      class << self
        def open
          IO.pipe
        end # open
      end # << self
    end # class::Memory < Abstract
  end # class::Pipe
end # module::Yaram