module Yaram
  class Session
=begin    
    class << self
      attr_accessor :reply_to, :context, :uuid, :idx

      @@contexts = []

      def start(msg = nil)
        return yield(new) if msg.nil?
        
        rpt, @reply_to = @reply_to, msg.reply_to
        cid, @context  = @context, msg.context
        begin
          yield self
        ensure
          @reply_to   = rpt
          @context_id = cid
        end # begin
      end # start(msg)

      def gen_context_prefix
        @uuid     = "#{UUID.generate}-#{Process.pid}"
        @idx      = -1
      end # gen_context_prefix
      
      def contexts
        @@contexts
      end # contexts
    end # << self
    
    # @return
    def initialize
      return unless block_given?
      Yaram::Session.contexts << Yaram::Session.context unless Yaram::Session.context.nil?
      Yaram::Session.context = cid.nil? ? "#{@@uuid}-#{@@idx += 1}" : cid
      # 1.339507818222046 s for 175,000
      begin
        yield(@context)
      ensure
        @context = @@contexts.pop
      end # begin
    end # initialize
=end   
  end # class::Session
end # module::Yaram
