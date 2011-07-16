require "uuid"

module Yaram
  class Message    
    
    class << self
      attr_reader :context
      @@contexts = []
      
      def gen_context_prefix
        @@uuid     = "#{UUID.generate}-#{Process.pid}"
        @@idx      = -1
      end # gen_context_prefix
            
      def in_context(cid = nil)
        return unless block_given?
        @@contexts << @context unless @context.nil?
        # @@idx += adds 0.7 s for 175,000
        @context = cid.nil? ? "#{@@uuid}-#{@@idx += 1}" : cid
        # 1.339507818222046 s for 175,000
        begin
          yield(@context)
        ensure
          @context = @@contexts.pop
        end # begin        
      end # in_context
    end # << self
    
    attr_accessor :reply_to, :context, :content
    
    def initialize(content, context = nil, reply_to = nil)
      @content    = content
      @context    = context
      @reply_to   = reply_to
    end
  end # class::Message
end # module::Yaram
