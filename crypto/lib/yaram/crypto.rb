require "yaram"
require "yaram/crypto/message"
require "yaram/crypto/version"
# Provided by MRI-1.9.2
# @todo add check and fallback
require "securerandom"
# http://rubydoc.info/gems/fast-aes/0.1.1/frames
# Only provides electronic codebook cipher block mode - no CBC
# http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Electronic_codebook_.28ECB.29
require "fast-aes"

module Yaram
  # Decryption was not successful - the shared key is probably not the same.
  class DecryptionError < ::Yaram::EncodingError; end

  # Provides encryption all message attributes except the from attribute.
  module Crypto
    class << self
      # [FastAES] the encryptor/decryptor
      attr_writer :aes
      # [Yaram::Encoder, Marshal, Ox] the object serializer
      attr_accessor :encoder
      
      # Generates a random key that can be shared by Yaram actors
      # @todo make this better.
      def keygen(bits = 128)
        raise NotImplementedError unless defined?(SecureRandom)
        raise ArgumentError, "bits must be one of 128, 192, or 256" unless [128,192,256].include?(bits)
        bytes = bits / 8
        return SecureRandom.base64(bytes)[0...bytes]
      end # keygen
      alias :genkey :keygen
      
      # Setup the Crypto module by loading the shared key from the given path.
      # If setup is not called then this process and the processes that it spawns will
      # not use Crypto when sending messages.
      #
      # When yaram/crypto is loaded, if ~/yaram/key exists #setup will be called 
      # automatically.
      #
      # @param [String] path full path to the file that contains the shared key.
      # @param [Symbol] mode (:file) or :string
      # @return [nil]
      def setup(path, mode = :file)
        if mode == :file
          raise LoadError, "''#{path}' does not exist" unless File.exists?(path)
          key = IO.read(path).chomp
        elsif mode == :string
          raise ArgumentError.new("'#{path}' must be a String when mode is :string") unless path.is_a?(String)
          key = path
        else
          raise ArgumentError, "'#{mode}' is not a supported setup mode"
        end # mode == :file
        
        @encoder, Yaram.encoder = Yaram.encoder, self unless @injected
        @injected               = true
        @aes                    = FastAES.new(key)
        nil
      end # setup(path)
      
      # Turn a potentially encrypted message into an object.
      # @param [String] m
      # @return [Object]
      def load(m)
        header, body = m[0..11], m[12..-1]
        raise EncodingError.new(header) unless header == "yaram:crypt:"
        o = @encoder.load(body)
        # if the message was not encrypted, just return it
        return o unless o.is_a?(::Yaram::Crypto::Message)
        payload = @aes.decrypt(o.payload)
        raise DecryptionError.new(o.from || "unknown sender") unless payload.slice!(0...12) == "yaram:crypt:"
        @encoder.load(payload)
      end # load(s)
      
      # Serialize and encrypt an object that can be sent over an insecure
      # channel to a Yaram::Actor.
      # @todo include the enryption library used in the URN.
      # @param [Object] o
      # @return [String]
      def dump(o)
        message = ::Yaram::Crypto::Message.new(@aes.encrypt("yaram:crypt:" + @encoder.dump(o)))
        # how does Yaram::Actor know to respond when the decryption fails?
        message.from = o.from if o.respond_to?(:from)
        "yaram:crypt:" + @encoder.dump(message)
      end # dump(o)
      
    end # << self
    
    if File.exists?(keyfile = File.expand_path("~/.yaram/key"))
      setup(keyfile)
    end
  end # module::Crypto
end # module::Yaram
