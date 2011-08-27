module Yaram
  module JsonEncoder
    extend Encoder
    replace(GenericEncoder)
    
    class << self
      def dump(o)
        "yaram:json: " + Yajl.dump(o)
      end # dump(o)
      
      def load(json)
        header,body = json[0..11], json[12..-1]
        raise EncodingError.new(header) unless header == "yaram:json: "
        Yajl.load(body)
      end # load(json)
      
    end # << self
  end # module::JsonEncoder
end # module::Yaram