module Yaram
  class JsonEncoder
    include Encoder
    prefix 'yaram:json: '
    replaces GenericEncoder
    
    def dump(o)
      @prefix + Yajl.dump(o)
    end # dump(o)
    
    def load(json)
      header,body = json[0..11], json[12..-1]
      raise EncodingError.new(header) unless header == @prefix
      Yajl.load(body)
    end # load(json)
  end # class::JsonEncoder
end # module::Yaram