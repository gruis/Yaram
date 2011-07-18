require "yaram/actor/proxy"
require "yaram/actor/async"
require "yaram/actor/sync"
require "yaram/actor/base"
require "yaram/actor/control"


module Yaram
  # @todo Add an #rpc and #rpc_noblock method
  # @todo setup the supervisor to restart the actor if it crashes
  # @todo trap Ctrl-C and stop actor
  module Actor

    # The process id of the process that was spawned to run this object
    attr_reader :spid
    # The address (URL) where this actor can be reached
    def address
      @inbox.address
    end # address

    # Spawn this object off into another process
    # @param [Hash] opts spawn options
    # @option opts [false, String, nil] :log
    # @option opts [Class, String, Yaram::Mailbox] :mailbox the mailbox to bind the actor to
    def spawn(opts = {})
      #puts "#{Process.pid} spawn(#{opts})"
      opts  = {:log => nil }.merge(opts.is_a?(Hash) ? opts : {})
      mbox  = Yaram::Mailbox.build(opts[:mailbox]).bind
      @connections ||= Hash.new {|hash,key| hash[key] = Mailbox.connect(key) }
      @def_to            = []
      @def_context       = []
      
      #puts "#{Process.pid} mbox: #{mbox}"

      pid   = Process.fork do
        at_exit { puts "#{$0} terminating" }
        begin
          $0      = "yaram_#{self.class.to_s.downcase.split("::")[-1]}"
  
          if opts[:log] == false
            STDOUT.reopen "/dev/null"
            STDERR.reopen "/dev/null"
          elsif opts[:log].is_a?(String)
            STDOUT.reopen opts[:log] + "stdout"
            STDERR.reopen opts[:log] + "stderr"
          else
            ts      = Time.new.to_i
            STDOUT.reopen "#{$0}.#{ts}.#{Process.pid}.stdout"
            STDERR.reopen "#{$0}.#{ts}.#{Process.pid}.stderr"
          end # opts[:log] == false

          subscribe(mbox)
        ensure
          mbox.close
        end # begin
        Process.exit
      end # Process.fork
      
      raise StartError, "unable to fork actor" if pid == -1
      @spid = pid
      
      at_exit do
        begin
          # @todo come up with some way to unregister the kill in case #detach is caused
          Process.getpgid(@spid) # raises ESRCH if process id already closed
          Process.kill(:TERM, @spid) 
        rescue Errno::ESRCH => e
        end # begin
      end # at_exit

      mbox.unbind
    end # spawn(opts = {})
    
    
    class << self
      # Start an actor in another process and return an Proxy object that can be used to communicate and supervise it.
      # @param [Yaram::Actor]
      def start(obj, opts = {})
        obj.extend(Yaram::Actor) unless obj.is_a?(Yaram::Actor)
        Proxy.new(obj.spawn(opts))
              .tap{|p| p.extend(Control).register(obj, p.outbox.address) }
      end # start
    end # class::self

    
    
    private
    
    # Publish a message and don't wait for a response.
    # Is not thread-safe; you need to synchronize with the lock before calling.
    # @param [Message] msg the thing to publish
    def publish(msg)
      #@indents ||= []
      #puts "#{@indents.join("")}#{Process.pid} publish(#{msg.inspect})"
      msg.from(@address)
      @connections[msg.to].write("#{Yaram.encoder.dump(msg)}]]>]]>")
    end # publish(*msg)
    
    # @return
    def message(msg, to = nil)
      publish(Message.new(msg).to(to || @def_to[-1]).context(@def_context[-1]))
    end # message(msg, to = nil)
    
    # Reply to a received message, or ensure that a reply will be sent.
    # If a block is given reply will keep track of any replies sent during the life of the block. If no
    # reply is sent then the result of the block will be sent as a final reply.
    # If a block is not given then a reply (msg) will be sent.
    # @param [Object] msg the reply to send
    # @return [Object] msg
    def reply(msg)
      #@indents ||= []
      #puts "#{@indents.join("")}#{Process.pid} reply(#{msg.inspect})"
      if block_given?
        #@indents << "   "
        @replied = false # probably not the right approach
        yield.tap do |implicit| 
            publish( Reply.new(implicit).context(msg.context).to(msg.reply_to) ) unless @replied
        end
      else
        publish(Reply.new(msg, @def_context[-1]).to(@def_to[-1]))
        @replied = true  
      end # block_given?
      msg
    end # reply
    
    # Start a session
    # @return
    def session(def_context, def_to = nil)
      #puts "#{Process.pid} session(#{def_context}, #{def_to})"
      @def_to.push(def_to)
      @def_context.push(def_context)
      begin
        yield if block_given?
      ensure
        @def_to.pop
        @def_context.pop
      end # begin
    end # session(def_to, def_context)
    
    
    # Retrieve a message.
    # Is not thread-safe; you need to synchronize with the lock before calling.
    # Yaram::Actor is not optimized for get, @msgs container should be pre-sorted if get 
    # optimization is required.
    # @todo stop using Message.context
    # @return
    def get(opts = {})
      opts = { :timeout => 1, :def => nil, :type => Message }.merge(opts)
      #puts "#{Process.pid} #{self.class}#get(#{opts})"
      begin
        waituntil = Time.new.to_i + opts[:timeout]
        while Time.new.to_i <= waituntil && @msgs[@def_context[-1]].select{|m| m.instance_of?(opts[:type]) }.empty?
          messages(opts[:timeout])
        end # Time.new.to_i <= waituntil
        return opts[:def] if (@msgs[@def_context[-1]].select{|m| m.instance_of?(opts[:type])}).empty?
        idx = @msgs[@def_context[-1]].find_index{|m| m.instance_of?(opts[:type]) }
        return @msgs[@def_context[-1]].delete_at(idx).content
      rescue EncodingError => e
        raise e.extend(::Yaram::Error)#.add_data(msgs)
      rescue Exception => e
        raise e.extend(::Yaram::Error)
      end # begin
    end # get_msg
    
    # Retrieve any raw messages that are waiting to be processed.
    # @return [Array] messages
    def messages(timeout = 0)
      #puts "#{Process.pid} #{self.class}#messages(#{timeout})"
      return @msgs if @inbox.select(timeout).nil?
      msgs = ""
      while true
        msgs += @inbox.read
        break if msgs[-6..-1] == "]]>]]>"
        break if @inbox.select(0).nil?
      end # true
      msgs.split("]]>]]>")
          .map{|o| Yaram.encoder.load(o) }
          .each {|m| @msgs[m.context].push(m) }
      @msgs
    end # messages
    
    # Send a message and wait for a response
    # Sychrnozises with the lock, so it's thread-safe.
    # @param [Message] a message to send
    # @return [Object] the response to the message
    #
    # @todo ensure that the reply is for the request: context ids?
    # there is nothing preventing the actor from publishing unsollicited events
    def request(msg, opts = {})
      @lock.synchronize do
        session((msg.context || msg.context(Message.newcontext).context), msg.to) do
          publish(msg.reply(@address))
          opts[:type] = Reply
          get(opts)          
        end # session
      end # synchronize do 
    end # send(msg, opts = {})

    # Subscribe to an input stream.
    # If a block is provided all decoded messages will be passed to it. Otherwise 
    # a local method will be called based on the message received.
    # @param [IO] input the source of messages
    # @param [IO] output where to send any replies
    # Does not return
    def subscribe(mbox)
      #puts "#{Process.pid} subscribe(#{mbox})"
      @inbox   = mbox
      @address = mbox.address
      @def_to ||= []
      @def_context ||= []
      
      loop do
        msgs = ""
        begin
          @inbox.select(0)
          true while (msgs += @inbox.read)[-6 .. -1] != "]]>]]>"
          msgs = msgs.split("]]>]]>")
          while (msg = msgs.shift) do
            begin
              message = Yaram.encoder.load(msg)
              session(message.context, message.reply_to) do
                begin
                  if block_given?
                    yield(message)
                  else
                    meth, *args = message.content
                    unless (meth.is_a?(String) && !meth.empty?) || meth.is_a?(Symbol)
                      reply(ArgumentError.new"'#{meth.inspect}' must be a String or Symobl")
                      next
                    end
                    message.reply? ? (reply(message) { send(meth, *args) }) : send(meth, *args)
                  end # block_given?
                rescue Exception => e
                  reply(e)
                  raise e.extend(::Yaram::Error)
                end # begin                
              end # session
            rescue Exception => e
              puts "=-=-=-=-=-=-= processing failure =-=-=-=-=-=-="
              puts "failed for message:"
              puts "#{msg}"
              raise e
            end # begin
          end # do  |msg|
          
        rescue Exception => e
          puts "=-=-=-=-=-=-= message queue =-=-=-=-=-=-="
          puts "#{msgs.is_a?(Array) ? msgs.join("\n") : msgs}"
          puts "=-=-=-=-=-=-= message queue end =-=-=-=-=-=-="
          raise e.extend(::Yaram::Error)
        end # begin
      end # loop do
    end # subscribe(io)
        
  end # module::Actor
end # module::Yaram
