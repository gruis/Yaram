module Yaram
  # Yaram::Encoders are used to encode Yaram messages before they are sent to remote Actors. Encoders 
  # can be chained in order to provide encoding features, e.g., encryption and compression.
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
  module Encoder
    # [Yaram::Encoder, Marshal, Ox] the object serializer
    attr_accessor :encoder
    
    # Inserts this Encoder into the Yaram encoding chain.
    # Encoders will be called in the reverse order in which
    # they were injected. The next encoder in the chain will
    # be assigned assigned to @encoder.
    #
    # @example
    #   module Crypto
    #     extend ::Yaram::Encoder
    #     ...
    #     inject
    #   end
    def inject
      return if Yaram::Encoder.injected?(self)
      @encoder, Yaram.encoder  = Yaram.encoder, self 
      Yaram::Encoder.injected(self)
    end # inject
    
    def dump(o)
      # by default pass the object to the next encoder in the chain
      @encoder.dump(o)
    end # dump(o)
    
    def load(s)
      # by default pass the string to the next decoder in the chain
      @encoder.load(s)
    end # load(s)
    
    class << self
      def injected?(m)
        (@injected ||= {})[m]
      end # injected?(m)
      
      def injected(m)
        (@injected ||= {})[m] = true
      end # injected(m)
      
    end # << self
  end # module::Encoder
end # module::Yaram
