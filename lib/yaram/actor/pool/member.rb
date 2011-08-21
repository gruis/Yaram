module Yaram
  module Actor
    class Pool
      
      # A pool member is an actor that is a member of a work queue. It or any one of its peers will
      # be selected to handle a message as it arrives.
      #
      # @todo support broadcasting messages to all peers
      # @todo support registration with a Pool
      module Member
        
        def _yaram_pool_member_available?
          puts "#{Process.pid} _yaram_pool_member_available?"
          # Sends an implicit reply telling the requester (should be the pool) that this 
          # instance is available to process a message.
          reply(:_yaram_pool_member_available)
        end # _yaram_pool_member_available?
        
      end # module::Member
    end # class::Pool
  end # module::Actor
end # module::Yaram