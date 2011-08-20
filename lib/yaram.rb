require "thread"

begin
  require "ox"
rescue LoadError => e
  # we'll use Marshal instead
end # begin

require "yaram/version"
require "yaram/ext/yaram"
require "yaram/error"
require "yaram/message"
require "yaram/reply"
require "yaram/session"
require "yaram/actor"
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
      if !(((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.7").satisfied_by?(oxgem.version))
        include Marshal
        def load(xml)
          super(xml)
        end # load(xml)
      else
        include Ox
        def load(xml)
          begin
            super(xml, :mode => :object)
          rescue Exception => e
            raise ParseError, "unable to parse '#{xml}'"
          end # begin
          
        end
      end # ((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.2").satisfied_by?(oxgem.version)

      def dump(o)
        super(o)
      end
    end # << self
  end # module::Encoder
end # module::Yaram
