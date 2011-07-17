module Yaram
  # @todo Add an #rpc and #rpc_noblock method
  # @todo setup the supervisor to restart the actor if it crashes
  # @todo trap Ctrl-C and stop actor
  module Actor
    
    def address
      @pipe.address
    end # address
    
    # Send a message asynchronously
    def !(meth, *args)
      publish([meth, *args])
    end 
    
    # Send a message and wait for a reply
    def sync(meth, *args)
      request([meth, *args])
    end
    
    # If a request results in the actor restarting then resend the last request.
    # This is currently not correct behavior because the msg that caused the actor
    # to crash was msg N-1 not N. We will loose one message instead of two, but we
    # want to loose zero.
    # @return
    def recover(times = 1)
      begin
        yield
      rescue Yaram::ActorRestarted => e
        times -= 1
        times > -1 ? retry : raise(e)
      end # begin
    end # retry(times = 1)
    
    # Stop the actor and start it again.
    # The actor's current message queue will be written to a log file.
    # @return
    def restart
      stop
      @tpid, @in, @out = Yaram::Actor.start(@actorklass)
    end # restart
    
    def stop
      begin
        Process.getpgid(@tpid)
        Process.kill(:TERM, @tpid)
      rescue Errno::ESRCH => e
      end # begin
    end # close
        
    class << self
      
      # @return
      def extended(c)
        if c.is_a?(Class)
          # do something
          return
        end # c.is_a?(Class)
        # spawn as an actor
      end # extended(c)
      
      # @return
      def wrap(obj, opts = {})
        opts = {:log => nil }.merge(opts.is_a?(Hash) ? opts : {})
        pipe = Yaram::Pipe.make_pipe(opts[:pipe])
        #....
        obj.extend(self)
        obj.send(:prepare)
        obj.send(:subscribe)
      end # wrap(obj, opts = {})
      
      # Start an instance of Class that includes Yaram::Actor, or inherits from Yaram::Actor::Base
      def start(klass, opts = {})
        opts = {:log => nil }.merge(opts.is_a?(Hash) ? opts : {})
        pipe = Yaram::Pipe.make_pipe(opts[:pipe])
        
        pid = Process.fork do
          at_exit { puts "#{$0} terminating" }
          begin
            pipe.connect(:client)
            $0      = "yaram_#{klass.to_s.downcase.split("::")[-1]}"
            
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
           
            klass.new.send(:subscribe, pipe)
          ensure
            pipe.close
          end # begin
          Process.exit
        end # Process.fork
        
        raise StartError, "unable to fork actor" if pid == -1
        
        pipe.connect
        
        at_exit do
          begin
            Process.getpgid(pid) # raises ESRCH if process id already closed
            Process.kill(:TERM, pid) 
          rescue Errno::ESRCH => e
          ensure
            pipe.close
          end # begin
        end # at_exit

        #puts "#{klass} is running in process #{pid}"
        [pid, pipe]
      end # start
    end # class::self

    
    
    private

    # Prepare an Actor for work.
    # @lock will be created for thread synchronization.
    #
    # When called by the process that is creating an actor a Class must be passed in.
    # @tpid, @in, and @out will be created
    #
    # When called by the process that will be the actor, no klass can be provided.
    #
    # @return
    def prepare(klass = nil, opts = {})
      @lock = Mutex.new
      @msgs = {}
      Message.gen_context_prefix
      
      if klass.nil?
        # We are the actor process
        @tpid = Process.ppid
        return self
      end # klass.nil?
      
      raise ArgumentError, "klass '#{klass}' must be an instantiatable class" unless klass.is_a?(Class)
      @actorklass  = klass
      @tpid, @pipe = Yaram::Actor.start(@actorklass, opts)
      @tpid
    end # prepare
    
    # Publish a message and don't wait for a response.
    # Is not thread-safe; you need to synchronize with the lock before calling.
    # @param [Object] msg the thing to publish
    # @todo raise an execption if @out is closed on tracker process is down
    def publish(msg)
      #@indents ||= []
      #puts "#{@indents.join("")}#{Process.pid} publish(#{msg.inspect})"
      begin
        @pipe.write("#{Yaram.encoder.dump(msg.is_a?(Message) ? msg : Message.new(msg))}]]>]]>")
      rescue Errno::EPIPE => e
        @tpid, @in, @out = Yaram::Actor.start(@actorklass)
        raise ActorRestarted, "#{@actorklass} process was automatically restarted; resend message(s) manually"
      end # begin
    end # publish(*msg)
    
    # Reply to a received message, or ensure that a reply will be sent.
    # If a block is given reply will keep track of any replies sent during the life of the block. If no
    # reply is sent then the result of the block will be sent as a final reply.
    # If a block is not given then a reply (msg) will be sent.
    # @param [Object] msg the reply to send
    # @return [Object] msg
    def reply(msg = nil)
      #@indents ||= []
      #puts "#{@indents.join("")}#{Process.pid} reply(#{msg.inspect})"
      if block_given?
        #@indents << "   "
        @replied = false # probably not the right approach
        implicit = yield
        publish(Message.new(implicit, Message.context)) unless @replied
      else
        publish(Message.new(msg, Message.context))
        @replied = true  
      end # block_given?
      msg
    end # reply
    
    # Retrieve a message.
    # Is not thread-safe; you need to synchronize with the lock before calling.
    # @return
    def get(opts = {})
      opts = { :timeout => 1, :def => nil }.merge(opts)
      begin
        waituntil = Time.new.to_i + opts[:timeout]
        while Time.new.to_i <= waituntil && (@msgs[Message.context] ||= []).empty?
          messages(opts[:timeout])
        end # Time.new.to_i <= waituntil
        return opts[:def] if (@msgs[Message.context] ||= []).empty?
        return @msgs[Message.context].pop.content
      rescue EncodingError => e
        raise e.extend(::Yaram::Error)#.add_data(msgs)
      rescue Exception => e
        raise e.extend(::Yaram::Error)
      end # begin
    end # get_msg
    
    # Retrieve any raw messages that are waiting to be processed.
    # @return [Array] messages
    def messages(timeout = 0)
      return @msgs if @pipe.select(timeout).nil?
      msgs = ""
      true while ((msgs += @pipe.readpartial(4096))[-6..-1] != "]]>]]>")
      msgs.split("]]>]]>")
          .map{|o| Yaram.encoder.load(o) }
          .each {|m| (@msgs[m.context] ||= []) << m }
      @msgs
    end # messages
    
    # Send a message and wait for a response
    # Sychrnozises with the lock, so it's thread-safe.
    # @return [Object] the response to the message
    #
    # @todo ensure that the reply is for the request: context ids?
    # there is nothing preventing the actor from publishing unsollicited events
    def request(msg, opts = {})
      @lock.synchronize do
        Message.in_context do |cid|
          publish(Message.new(msg, cid).reply(address))
          get(opts)
        end #  |cid|
      end # synchronize do 
    end # send(msg, opts = {})

    # Subscribe to an input stream.
    # If a block is provided all decoded messages will be passed to it. Otherwise 
    # a local method will be called based on the message received.
    # @param [IO] input the source of messages
    # @param [IO] output where to send any replies
    # Does not return
    def subscribe(pipe)
      @pipe = pipe
      loop do
        msgs = ""
        begin
          @pipe.select(0)
          true while (msgs += @pipe.readpartial(4096))[-6 .. -1] != "]]>]]>"
          msgs = msgs.split("]]>]]>")
          while (msg = msgs.shift) do
            begin
              if block_given?
                yield(Yaram.encoder.load(msg).content)
              else
                message = Yaram.encoder.load(msg)
                Message.in_context(message.context) do 
                  meth, *args = message.content
                  unless (meth.is_a?(String) && !meth.empty?) || meth.is_a?(Symbol)
                    #raise ArgumentError.new("'#{meth.inspect}' must be a String or Symobl")
                    reply(ArgumentError.new"'#{meth.inspect}' must be a String or Symobl")
                    next
                  end
                  message.reply? ? (reply { send(meth, *args) }) : send(meth, *args)
                end # Message.in_context(message.context) do 
              end # block_given?
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
    
    
    # Confirms that the other side is up and capable of communication.
    # @return
    def require_channel
      begin
        Process.getpgid(@tpid)
      rescue Errno::ESRCH => e
        # no such process
        raise e.extend(::Yaram::Error)
      end # begin
    end # require_channel
    
    
    
    public
    
    # Allows for inheritence of Yaram::Actor
    class Base
      include Actor      
      def initialize
        prepare
      end # initialize
    end # class::Base
    module Unobtrusive
      def spawn(opts = {})
        Actor.start(self, opts)
      end # spawn(opts = {})
    end # module::Unobtrusive
    class Simple < Base
      def initialize(klass = nil, opts = {})
        prepare(klass, opts)
      end 
      
      def method_missing(meth, *args)
        self.!(meth, *args)
      end 
    end # class::Simple < Base
  end # module::Actor
end # module::Yaram
