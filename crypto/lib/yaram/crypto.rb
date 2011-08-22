require "yaram"
require "yaram/crypto/message"
require "yaram/crypto/version"
# Provided by MRI-1.9.2
# @todo add check and fallback
require "securerandom"
# http://rubydoc.info/gems/fast-aes/0.1.1/frames
# only provides cipher block chaining
require "fast-aes"

module Yaram
  module Crypto
    class << self
      attr_writer :aes, :encoder
      
      # Generates a random key that can be shared by Yaram actors
      # @todo make this better.
      def keygen(bits = 128)
        raise NotImplementedError unless defined?(SecureRandom)
        raise ArgumentError, "bits must be one of 128, 192, or 256" unless [128,192,256].include?(bits)
        bytes = bits / 8
        return SecureRandom.base64(bytes)[0...bytes]
      end # keygen
      
      def setup(path)
        raise LoadError, "''#{path}' does not exist" unless File.exists?(path)
        @encoder, Yaram.encoder = Yaram.encoder, self
        @aes                    = FastAES.new(IO.read(path).chomp)
      end # setup(path)
      
      def load(s)
        o = @encoder.load(s)
        return o unless o.is_a?(::Yaram::Crypto::Message)
        # @todo detect failure and somehow notify the sender...
        @encoder.load(@aes.decrypt(o.payload))
      end # load(s)
      
      def dump(o)
        message = Message.new(@aes.encrypt(@encoder.dump(o)))
        # how does Yaram::Actor know to respond when the decryption fails?
        message.from = o.from if o.respond_to?(:from)
        @encoder.dump(message)
      end # dump(o)
      
    end # << self
    
    if File.exists?(keyfile = File.expand_path("~/.yaram/key"))
      setup(keyfile)
    end
  end # module::Crypto
end # module::Yaram
