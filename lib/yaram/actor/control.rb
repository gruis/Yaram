module Yaram
  module Actor
    
    # Actor::Control is a mixin used to keep track of Actors and restart them
    # as necessary.
    # @example
    #   Proxy.new(obj.spawn(opts))
    #        .tap{|p| p.extend(Control).register(obj, p.outbox.address) }
    module Control
      
      # Register an actor object to be controlled/monitored.
      # @param [Yaram::Actor] obj the actor to watch and restart as necessary
      # @param [String] spaddress the address of the actor
      # @return [Control] the controller
      def register(obj, spaddress)
        @snapshot  = obj
        @spid      = obj.spid
        @spaddress = spaddress
        self
      end # register(obj)
      
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
      # @todo ensure that the actor binds to the same address
      # @return
      def restart
        stop
        @snapshot.spawn(:mailbox => @spaddress)
        register(@snapshot, @spaddress)
      end # restart
      
      # Stops the actor process.
      # Does not stop actors that aren't running on the same machine.
      # @return [Control] the controller
      def stop
        begin
          Process.getpgid(@spid)
          Process.kill(:TERM, @spid)
        rescue Errno::ESRCH => e
        end # begin
        self
      end # close
      
      
      # If the actor crashes at anytime during the life of the block it will be restarted.
      # @param [Integer] times the number of time to restart the actor -1 causes means no limit
      # @return
      def autorestart(times = -1)
        raise NotImplementedError
        restarted = 0
        begin
          yield if block_given?
        rescue Yaram::ActorDied => e
          restarted += 1
          raise(e) if times == 0 || times - restarted == 0
          restart
          retry          
        end # begin
        #begin
        #  @pipe.write("#{Yaram.encoder.dump(msg.is_a?(Message) ? msg : Message.new(msg))}]]>]]>")
        #rescue Errno::EPIPE => e
        #  @tpid, @in, @out = Yaram::Actor.start(@actorklass)
        #  raise ActorRestarted, "#{@actorklass} process was automatically restarted; resend message(s) manually"
        #end # begin
      end # autorestart
      
      
    end # module::Control
  end # module::Actor
end # module::Yaram
