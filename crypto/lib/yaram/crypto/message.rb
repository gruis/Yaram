module Yaram
  class Crypto
    class Message
      
      # the content of the message
      attr_reader :payload
      # the version of the yaram-crypto gem used to encrypt the message
      attr_reader :version
      # the source of the message - if it can't be decrypted this actor will be notified
      attr_accessor :from
      
      def initialize(payload)
        @payload = payload
        @version = ::Yaram::Crypto::VERSION
      end
      
    end # class::Message
  end # class::Crypto
end # module::Yaram