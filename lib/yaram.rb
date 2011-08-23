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
    # Assign a custom encoder to either use a diferent serialization library, or perform extra transformation
    # on messages before they are sent. For example the yaram-crypto library chains on top of the standard
    # yaram encoder by reassigning the Yaram.encoder to itself, but also keeping the original encoder.
    #
    # All  custom encoders are expected to add a 12 character header to the message and raise an EncodingError
    # if the message they receive to decode does not contain the same header.
    #
    # @see Yaram::Crypto#dump
    # @see Yaram::Crypto#load
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
          header,body = xml[0..11], xml[12..-1]
          raise EncodingError.new(header) unless header == "yaram:plain:"
          super(body)
        end # load(xml)
      else
        include Ox
        def load(xml)
          header,body = xml[0..11], xml[12..-1]
          raise EncodingError.new(header) unless header == "yaram:plain:"
          begin
            super(body, :mode => :object)
          rescue Exception => e
            raise ParseError, "unable to parse '#{body}'"
          end # begin
          
        end
      end # ((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.2").satisfied_by?(oxgem.version)

      def dump(o)
        "yaram:plain:" + super(o)
      end
    end # << self
  end # module::Encoder
end # module::Yaram
