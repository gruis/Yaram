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
    
    # Replaces one encoder module in the Yaram encoding chain.
    # @example
    #     module JsonEncoder
    #       extend ::Yaram::Encoder
    #       replace(Yaram::GenericEncoder)
    #       ...
    #     end
    # @see Yaram::Encoder.replace
    def replace(old_e, new_e = self)
      Yaram::Encoder.replace(old_e, new_e)
    end # replace(old, new = nil)
    
    def dump(o)
      # by default pass the object to the next encoder in the chain
      @encoder.dump(o)
    end # dump(o)
    
    def load(s)
      # by default pass the string to the next decoder in the chain
      @encoder.load(s)
    end # load(s)
    
    
    class << self
      include Enumerable
      
      # Replaces one encoder module in the Yaram encoding chaing
      # with another. Use replace when you want to substitute
      # the generic encoder with another.
      # @param [Module, Object] old_e the encoder to replace
      # @param [Module, Object] new_e the encoder to use instead of old_e
      # @example
      #     Yaram::Encoder.replace(Yaram::GenricEncoder, SuperSpecialEncoder.new)
      def replace(old_e, new_e)
        if Yaram.encoder == old_e
          new_e.encoder = Yaram.encoder.encoder
          Yaram.encoder = new_e
        end # Yaram.encoder == old_e

        e = Yaram
        while !e.encoder.nil?
          e = e.encoder.tap do
                if e.encoder == old_e
                  new_e.encoder = e.encoder.encoder
                  e.encoder     = new_e 
                end # e.encoder == old_e
              end # tap
        end # !e.encoder.nil?
      end # replace(old_e, new_e)
      
      def clear_injections
        @injected = {}
      end # clear_injections
      
      # Insert an Encoder into the Yaram encoding chain.
      # Encoders will be called in the reverse order in which
      # they were injected. The next encoder in the chain will
      # be assigned assigned to @encoder.
      #
      # @example
      #   Yaram::Encoder.inject(SuperFastEncoder.new)
      # @example
      #   Yaram::Encoder.inject(SuperFastEncoderSingleton)
      def inject(m)
        return if Yaram::Encoder.injected?(m)
        raise ArgumentError, "'#{m}' must have a settable encoder attribute" unless [:encoder=,:encoder].all? {|f| m.respond_to?(f) }
        m.encoder, Yaram.encoder  = Yaram.encoder, m
        injected(m)
      end # inject(m)
      
      def injected?(m)
        (@injected ||= {})[m]
      end # injected?(m)
      
      def injected(m)
        (@injected ||= {})[m] = true
      end # injected(m)
      
      def all
        encs = []
        e = Yaram.encoder
        while !e.nil? && e.respond_to?(:encoder)
          encs.push(e)
          e = e.encoder
        end # !e.nil? && e.respond_to?(:encoder)
        encs        
      end # all
      
      def last
        all[-1]
      end # last
      
      # Yields each encoder in the Yaram encoding chain.
      def each
        block_given? ? all.each {|e| yield e } : all
      end # each
      
    end # << self
  end # module::Encoder
end # module::Yaram
