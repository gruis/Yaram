require "uuid"

module Yaram
  class Message    
    
    class << self
      def gen_context_prefix
        @@uuid     = "#{UUID.generate}-#{Process.pid}"
        @@idx      = -1
      end # gen_context_prefix
            
      def newcontext
        if block_given?
          yield "#{@@uuid}-#{@@idx += 1}"
        else
          "#{@@uuid}-#{@@idx += 1}"
        end # block_given?
      end # newcontext
      
      def json_create(o)
        new(o["content"], o["context"], o["reply_to"], o["from"], o["to"])
      end # json_create(o)
    end # << self
    
    attr_accessor :content
    attr_writer :to, :reply_to, :context, :from
    
    def initialize(content, context = nil, reply_to = nil, from = nil, to = nil)
      @content    = content
      @context    = context
      @reply_to   = reply_to
      @from       = from
      @to         = to
    end
    
    def reply?
      @reply
    end # reply?
    
    def to(to = nil)
      return @to if to.nil?
      @to = to
      self
    end # to(to = nil)
    
    def context(ctx = nil)
      return @context if ctx.nil?
      @context = ctx
      self
    end # context(ctx = nil)
    
    def reply_to(rto = nil)
      return (@reply_to || @from) if rto.nil?
      @reply_to = rto
      self
    end # reply_to(rto = nil)
    
    def from(frm = nil)
      return @from if frm.nil?
      @from = frm
      self
    end # from(frm = nil)
    
    
    def reply(to = nil)
      @reply    = true
      @reply_to = to
      self
    end # reqreply
    
    def eql?(other)
      puts "#{self} == #{other}"
      content == other.content && context == other.context && to == other.to && reply_to == other.reply_to
    end # ==(other)
    
    def to_s
      content
    end # to_s
    
    def details
      "to: #{to}\n" + "from: #{from}\n" + "reply_to: #{reply_to}\n" + "content: #{content}\n"
    end # details
    
  end # class::Message
  Message.gen_context_prefix
end # module::Yaram
