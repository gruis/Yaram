module Yaram
  module Actor
    module Control
      
      # @return
      def register(obj, spaddress)
        @snapshot  = obj
        @spid      = obj.spid
        @spaddress = spaddress
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
      
      def stop
        begin
          Process.getpgid(@spid)
          Process.kill(:TERM, @spid)
        rescue Errno::ESRCH => e
        end # begin
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
