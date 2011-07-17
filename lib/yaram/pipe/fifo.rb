require "uuid"
module Yaram
  class Pipe
    class Fifo < Pipe

      def initialize
        Dir.mkdir("/tmp/actors/") unless File.exists?("/tmp/actors")
        fifopref = "/tmp/actors/#{Process.pid}-"
        fifo0 = "#{fifopref}#{UUID.generate}.fifo"
        fifo1 = "#{fifopref}#{UUID.generate}.fifo"
        system("mkfifo #{fifo0}")
        system("mkfifo #{fifo1}")
        @ios = [[open("#{fifo0}", "r+"), open("#{fifo1}", "w+"), "fifo://#{fifo0}"], 
                [open("#{fifo1}", "r+"), open("#{fifo0}", "w+"), "fifo://#{fifo1}"]]
        @ios[0][1].sync = true
        @ios[1][1].sync = true
        super(*[*@ios[0][0..1], *@ios[1][3..4]])
      end
      
      def close
        super
        File.delete(@address.split("fifo://")[-1])
      end # close
      
    end # class::Fifo < Pipe
  end # class::Pipe
end # module::Yaram