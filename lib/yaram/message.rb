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
        @context = cid.nil? ? "#{@@uuid}-#{@@idx += 1}" : cid

        # 2.37100 s for 175,000
        begin
          yield(@context)
        ensure
          @context = @@contexts.pop
        end # begin
        
        # 2.33797 s for 175,000 
        #r = yield(@context)
        #@context = contexts.pop
        #r
        
        #yield(@context).tap{ @@contexts.pop }
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
