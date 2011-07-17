module Yaram
  class Mailbox
    class Unix < Mailbox
      
      # @return
      def initialize
        raise NotImplementedError
        pread,cwrite = IO.pipe
        cwrite,pread = IO.pipe
      end # initialize
      
      # @return
      def connect
        cwrite.close
        cread.close
        @io = pwrite
        super()
      end # connect
      
      # @return
      def bind
        pwrite.close
        pread.close
        @io = cread
        super()
      end # bind
      
    end # class::Unix < Mailbox
  end # class::Mailbox
end # module::Yaram