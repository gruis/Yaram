require "thread"
require "fcntl"
begin
  require "ox"
rescue LoadError => e
  # we'll use Marshal instead
end # begin

require "yaram/version"
require "yaram/error"
require "yaram/message"
require "yaram/reply"
require "yaram/session"
require "yaram/actor"
require "yaram/pipe"
require "yaram/mailbox"

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
      if !(((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.2").satisfied_by?(oxgem.version))
        include Marshal
        def load(xml)
          super(xml)
        end # load(xml)
      else
        include Ox
        def load(xml)
          super(xml, :mode => :object)
        end
      end # ((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.2").satisfied_by?(oxgem.version)

      def dump(o)
        super(o)
      end
    end # << self
  end # module::Encoder
end # module::Yaram
