require "yaram"
require "yaram/crypto/version"
require "fast-aes"
# Provided by MRI-1.9.2
# @todo add check and fallback
require "securerandom"

module Yaram
  module Crypto
    class << self

      # Generates a random key that can be shared by Yaram actors
      # @todo make this better.
      def keygen(bits = 128)
        raise NotImplementedError unless defined?(SecureRandom)
        raise ArgumentError, "bits must be one of 128, 192, or 256" unless [128,192,256].include?(bits)
        
        return SecureRandom.uuid.gsub("-","") if bits == 128
        return SecureRandom.uuid.gsub("-","") + SecureRandom.uuid.gsub("-","") if bits == 256
        return SecureRandom.uuid.gsub("-","") + SecureRandom.uuid.gsub("-","")[0..15]
      end # keygen

    end # << self

  end # module::Crypto
end # module::Yaram
