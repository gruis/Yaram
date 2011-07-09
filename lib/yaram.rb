require "ox"
require "thread"
require "fcntl"

require "yaram/version"
require "yaram/error"
require "yaram/actor"
require "yaram/pipe"

module Yaram
  class << self
    def encoder=(encdr)
      @encoder = encdr
    end
    def encoder
      @encoder ||= ::Yaram::Encoder
    end
  end # << self
  
  module Encoder
    class << self
      include Ox
      def load(xml)
        super(xml, :mode => :object)
      end
      def dump(o)
        super(o)
      end
    end # << self
  end # module::Encoder
end # module::Yaram
