module Yaram
  module Actor
    # An actor pool is a group of similar actors (instances of the same Class) that can all respond
    # to a message. The pool manages the actors, receives a message and selects an actor that volunteers
    # to answer the message.
    #
    # It's similar to the AMQP concept of a Work Queue.
    # @see http://www.rabbitmq.com/tutorials/tutorial-two-python.html
    class Pool
      include Yaram::Actor

      def initialize(*actor_addresses)
        # When a message is received requests for an actor to answer the message are sent to all 
        # registered actors starting with @actors[@last_used]. In that way actors are notified
        # in a round-robin pattern. The actor to use, is however, determined by whichever one
        # responds first, so the work distribution is not necessarily round-robin.
        @actors          = []
        @priority_notify = 0

        register(*actor_addresses)
        
        # @todo return the address of the pool
      end # initialize(*actor_addresses)
      
      # Registers one or more actors with the pool.
      # When the pool receives a message one of the registered
      # actors will be used to answer the message.
      def register(*actor_addresses)
        actor_address.each { |addr| @actors.push(addr) }
      end # register(*actor_addresses)
      
      # Sends an asychronous message to all actors.
      def broadcast(msg)
        raise NotImplementedError
      end # broadcast(msg)
      
    end # class::Pool
  end # module::Actor
end # module::Yaram
