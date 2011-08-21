require "yaram/actor/pool/member"

module Yaram
  module Actor
    # An actor pool is a group of similar actors (instances of the same Class) that can all respond
    # to a message. The pool manages the actors, receives a message and selects an actor that volunteers
    # to answer the message.
    #
    # It's similar to the AMQP concept of a Work Queue.
    # @see http://www.rabbitmq.com/tutorials/tutorial-two-python.html
    #
    # Send messages to the Pool's #address to have it distributed to the members.
    class Pool
      include Yaram::Actor

      attr_reader :address

      # Create a Pool.
      # @param [String, Actor] actor_addresses - the addresses or actors that should be registered.
      # @param [Hash] opts - any options that can be accepted by Pool::Actor.spawn plus a few more
      # @option opts [String] :restore_list file to use to keep track of members across restarts
      def initialize(*actor_addresses)
        @opts      = actor_addresses.last.is_a?(Hash) ? actor_addresses.pop : {}
        @opts      = {:restore_list => "#{self.class.name.gsub(":", "")}.restore"}.merge(@opts)
        @actors    = []
        @msg_queue = []
        
        register(*actor_addresses) unless actor_addresses.empty?
        
        @address = spawn(@opts) do |msg|
          #puts "#{Process.pid} #{self} received: #{msg}"
          #puts "#{Process.pid}  to: #{msg.to}"
          #puts "#{Process.pid}  from: #{msg.from}"
          #puts "#{Process.pid}  reply_to: #{msg.reply_to}"
          #puts "#{Process.pid}  content: #{msg.content}"
          # A worker is volunteering to handle a message
          if msg.content == :_yaram_pool_member_available
            # Do we have work to give?
            if !@msg_queue.empty?
              o_msg = @msg_queue.shift
              # explicitly set the reply_to address of the message to the original reply_to or 
              # the original from then resend the message to the actor that volunteered
              o_msg.reply_to(o_msg.reply_to || o_msg.from)
                   .from(address)
                   .to(msg.from)
              publish(o_msg)
            end # !@msg_queue.empty?
          # The message is from another actor directed at the pool
          else
            # This is a message for the pool controller
            if self.class.public_instance_methods.include?(msg.content[0])
              meth, *args = msg.content
              msg.reply? ? (reply(msg) { public_send(meth, *args) }) : public_send(meth, *args)
            # It is a message that should be given to a worker
            else
              @msg_queue.push(msg)
              ask_for_volunteers
            end # self.class.public_instance_methods.include?(msg.content[0])
          end # msg.content == _yaram_pool_member_available?
        end #  |msg|
      end # initialize(*actor_addresses)
      
      # Registers one or more actors with the pool.
      # When the pool receives a message one of the registered actors will be used to ansewer
      # the message.
      # @param [String, Actor] actor_addresses - the addresses or actors that should be registered.
      # @return [String] address of the pool
      def register(*actor_addresses)
        actor_addresses.each do |addr| 
          raise ArgumentError, "#{addr} must be an actor address, or respond to :address" unless addr.is_a?(String) || addr.respond_to?(:address)
          a = addr.respond_to?(:address) ? addr.address : addr
          next if @actors.include?(a)
          @actors.push(a)
        end
        
        save_member_list
        address
      end # register(*actor_addresses)
      
      # Remove one or more actors from the pool
      # @return [String] address of the pool
      def unregister(*member_addresses)
        member_addresses.each do |a|
          raise ArgumentError, "#{addr} must be an actor address, or respond to :address" unless addr.is_a?(String) || addr.respond_to?(:address)
          @actors.delete(addr.respond_to?(:address) ? addr.address : addr)
        end # |a|
        
        save_member_list
        address
      end # unregister(*member_addresses)
      
      # Sends an asychronous message to all actors.
      # @return [String] address of the pool
      def broadcast(msg)
        @actors.each { |addr| message(msg, addr) }
        address
      end # broadcast(msg)
      
      # Restores any members that were previously present in the pool before this process crashed.
      # @return [String] address of the pool
      def restore_members
        register(IO.read(@opts[:restore_list]).split("\n"))
        address
      end # restore_members
      
      # The actors that are a member of the pool
      # @return [Array] the addresses of the actors in the pool
      def members
        @actors
      end # members
      
      
    private
      
      # Send a broadcast message to the pool members asking for one that is free to receive a message.
      #
      # After the message is sent the first actor in the list of actors will be moved to the end of the
      # list. In that way actors are notified in a round-robin pattern. The actor to use, is however,
      # determiend by whichever one responds first, so the work is not necessarily distributed in a
      # round-robin pattern.
      def ask_for_volunteers
        @actors.each { |addr| message([:_yaram_pool_member_available?], addr) }
        @actors.push(@actors.shift)
      end # ask_for_volunteers
      
      # Saves the list of members so that it can be restored in the event that this pool crashes.
      def save_member_list
        File.open(@opts[:restore_list], "w+") { |f| f.puts(@actors) }
        self
      end # save_member_lsit
      
    end # class::Pool
  end # module::Actor
end # module::Yaram
