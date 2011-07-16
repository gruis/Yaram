module Yaram
  class Message    
    attr_accessor :reply_to, :context_id, :content
    
    def initialize(content, context = nil, reply = nil)
      @content    = content
      # @todo cache a base context prefix and reuse it
      @context_id = context.nil? ? UUID.generate : context
      @reply_to   = reply
    end
    
  end # class::Message
end # module::Yaram
