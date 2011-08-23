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
    # All  custom encoders are expected to add at least a 12 character header URN to the message and raise
    # an EncodingError if the message they receive to decode does not contain the same header. The URN may
    # be longer than 12 characters, but must be appended with spaces if it is not 12 characters.
    #
    # Duplicating URN prefixes across encoders is unwise. URNs that are known to have been used already are:
    #   - yaram:mrshl:
    #   - yaram:ox   :
    #   - yaram:crypt:
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
      if (((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.7").satisfied_by?(oxgem.version))
        
        include Ox
        
        # Load an object that was dumped using Ox.
        # @raise EncodingError if the expected URN prefix is not found.
        # @param [String] m
        def load(xml)
          header,body = xml[0..11], xml[12..-1]
          raise EncodingError.new(header) unless header == "yaram:ox:   "
          begin
            super(body, :mode => :object)
          rescue Exception => e
            raise ParseError, "unable to parse '#{body}'"
          end # begin
        end # load(xml)
        
        # Dump an object using Ox and prefix it with a URN.
        # @param [Object] o
        # @todo add the Ox version requirement to the prefix URN if the Ox format changes.
        def dump(o)
          "yaram:ox:   " + super(o)
        end # dump(o)
      else
        
        include Marshal
        
        # Load an object that was dumped using Marshal.
        # @raise EncodingError if the expected URN prefix is not found.
        # @param [String] m
        def load(m)
          header,body = m[0..11], m[12..-1]
          raise EncodingError.new(header) unless header == "yaram:mrshl:"
          super(body)
        end
        
        # Dump an object using Marshal and prefix it with a URN.
        # @param [Object] o
        # @todo determine version of Marshal being used and include it in the URN.
        def dump(o)
          "yaram:mrshl:" + super(o)
        end
      end # ((oxgem = Gem.loaded_specs["ox"]).is_a?(Gem::Specification)) && Gem::Requirement.new("~>1.2.2").satisfied_by?(oxgem.version)
      
    end # << self
  end # module::Encoder
end # module::Yaram
