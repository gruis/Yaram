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
    def initialize
      @prefix = self.class.prefix
    end # initialize
    
    def dump(o)
      raise NotImplementedError
    end # dump
    
    def load(s)
      raise NotImplementedError
    end # load(s)
    
    def prefix
      self.class.prefix
    end # prefix
    
    class << self
      def included(c)
        c.extend(ClassMethods)
      end # included(c)
      
      def prefixes
        @prefixes ||= {}
      end # prefixes

      def exclusives
        @exclusives ||= {}
      end # exclusives
      def encoders
        @encoders ||= {}
      end # encoders
      
      # Creates a new chain of encoders that can be used in place of the standard chain.
      # @todo register chains for reuse
      # @todo ensure that encoders that are exclusive of each other cannot be used in the same chain
      def newchain(*args)
        Chain.new(*args)
      end # newchain(*types)
    end # << self
    
    module ClassMethods
      # Register a prefix string for an encoder
      # @param [String] p the prefix - 12 characters
      # @param [Module, Object] m the encoder
      def prefix(p = nil, m = self)
        return @prefix if p.nil?
        @prefix = p
        Yaram::Encoder.prefixes[p] = m
        @prefix
      end # prefix(p)
      
      def replaces(old_e, new_e = self)
        (Yaram::Encoder.exclusives[old_e] ||= []).push(new_e)
        (Yaram::Encoder.exclusives[new_e] ||= []).push(old_e)
      end # replaces(old_e, new_e = self)
      
      # Specifies that this encoder's dump cannot be called before serialization.
      def require_serialization(req = true)
        @require_serialization = req
      end # after_serialization(after = true)
      def require_serialization?
        @require_serialization == true
      end # require_serialization?
      
      # Specifies that this encoder is capable of serializing objects. 
      # Only serializing encoders can be fist in the encoding chain.
      def is_a_serializer(serializer = true)
        self.instance_eval { include(::Yaram::Encoder::Serializer) } if serializer
      end # is_a_serializer(is = true)
    end # module::ClassMethods
    
    # A tagging module that marks the includer as an Encoder that can serialize Objects.
    # Only Serializers can be the first encoder in a Chain.
    module Serializer
    end # module::Serializer
    
    
    class Chain
      include Enumerable
      
      attr_accessor :encoder
      
      def initialize(head, *rest)
        head, *rest = head.split(",").map{|s| Yaram::Encoder.prefixes[s] } if head.is_a?(String)
        enc = (head.is_a?(Class) && ![:encoder, :dump, :load ].all?{|m| head.respond_to?(m) }) ? head.new : head
        raise "#{enc.inspect} must respond to #{self.class.api_methods}; missing: #{self.class.missing_api_methods(enc)}" unless self.class.missing_api_methods(enc).empty?        
        
        @encoder  = enc
        @encoders = all
        @decoders = @encoders.reverse
        
        rest.each do |type|
          self.add( (type.is_a?(Class) && ![:encoder, :dump, :load ].all?{|m| type.respond_to?(m) }) ? type.new : type )
        end # |chain, type|
        raise ConfigurationError.new("only serializing encoders can be first (#{@encoders[0]}) in the chain") unless @encoders[0].is_a?(Serializer)
      end # initialize(enc)

      def as_urlparam
        "encoder=#{all.map{|e| URI.encode(e.prefix) }.join(",")}"
      end # as_urlparam

      def add(enc)
        raise "#{enc.inspect} must respond to #{self.class.api_methods}; missing: #{self.class.missing_api_methods(enc)}" unless self.class.missing_api_methods(enc).empty?
        last.encoder = enc
        @encoders    = all
        @decoders    = @encoders.reverse
        raise ConfigurationError.new("only serializing encoders can be first (#{@encoders[0]}) in the chain") unless @encoders[0].is_a?(Serializer)
        self
      end # add(enc)
      
      def dump(o)
        encoded = o
        @encoders.each { |enc| encoded = enc.dump(encoded) }
        encoded
      end # dump(o)
      
      def load(s)
        decoded = s
        @decoders.each { |dec| decoded = dec.load(decoded) }
        decoded
      end # load(s)
      
      def replace(old_e, new_e)
        new_e = new_e.new if (new_e.is_a?(Class) && ![:encoder, :dump, :load ].all?{|m| new_e.respond_to?(m) })
        
        if @encoder.prefix == old_e.prefix
          new_e.encoder = @encoder.encoder
          @encoder      = new_e
        end # @encoder == old_e
        
        e = @encoder
        while !e.encoder.nil?
          e = e.encoder.tap do
                if e.encoder.prefix == old_e.prefix
                  new_e.encoder = e.encoder.encoder
                  e.encoder     = new_e 
                end # e.encoder == old_e
              end # tap
        end # !e.encoder.nil?
        
        @encoders = all
        @decoders = @encoders.reverse
      end # replace(old_e, new_e)
      
      def all
        encs = []
        e    = @encoder
        while !e.nil? && e.respond_to?(:encoder)
          encs.push(e)
          e = e.encoder
        end # !e.nil? && e.respond_to?(:encoder)
        encs        
      end # all
      
      # Yields each encoder in the chain.
      def each
        block_given? ? all.each {|e| yield e } : all
      end # each
      
      def last
        @encoders[-1]
      end # last
      
      def first
        @encoders[0]
      end # first
      
      def [](idx)
        @encoders[idx]
      end # [](idx)
      
      class << self
        def from_urlparam(p)
          new(URI.decode(p).split("encoder=")[-1].split("&",2)[0])
        end # from_urlparam

        def api_methods
          [:encoder, :dump, :load]
        end # api_methods
        def missing_api_methods(enc)
          [:encoder, :dump, :load ].reject{|m| enc.respond_to?(m) }
        end # missing_api_methods
      end # << self
    end # class::Chain

  end # module::Encoder
end # module::Yaram
