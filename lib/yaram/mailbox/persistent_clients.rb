module Yaram
  class Mailbox
    # A mixin used by Tcp and Unix mailboxes to keep track of multiple connections - one for each peer.
    module PersistentClients
      # Read a message from the first client connection that has sent data
      # @todo round-robin between the clients.
      # @todo don't block on the first select
      def read(bytes = 65536)
        begin          
          IO.select(@inboxes, nil, nil)[0][0].read_nonblock(bytes)
        rescue IO::WaitReadable, Errno::EINTR
          IO.select([@inboxes], nil, nil)
          retry
        end
      end # read(bytes)
      
      def select(timeout = 1)
        @bound ? IO.select(inboxes, nil, nil, timeout) : IO.select(nil, [@io], nil, timeout)
      end

      private
      
      # @return
      def inboxes
        raise NotImplementedError
      end # inboxes

    end # module::PersistentClients
  end # class::Mailbox
end # module::Yaram