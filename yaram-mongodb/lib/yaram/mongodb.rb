require "mongo"
require "bson"

require "yaram/mongodb/version"
require "yaram/mailbox"

module Yaram
  module Mongodb

    class Mailbox < ::Yaram::Mailbox
      def initialize(address = nil)
        @address  = address
        @buffer   = []
      end # initialize(url = nil)
      
      def bind(addr = nil)
        close if connected? || bound?
        addr ||= @address
        @cursor = Mongo::Cursor.new(connect_mongo(addr), :tailable => true, :order => [['$natural', 1]], :capped => true, :max => 20) # needs a wait data option
        @io     = @cursor.instance_variable_get(:@socket)
        @connected , @bound = false, true
        self
      end # bind(addr)

      def connect(addr = nil)
        addr ||= @address
        close if bound? || connected?
        @io = connect_mongo(addr)
        @connected , @bound = true, false
        self
      end
      
      def read(bytes = 65536)
        #puts "#{Process.pid} #{Time.new.to_i} #{self}.read(#{bytes})"

        sleep 0.055  # WTF why????

        messages = ""
        until (d = @cursor.next_document).nil?
          #puts "received ==>\n #{d["msg"]}\n"
          messages += d["msg"]
          sleep 0.001
        end # (d = @cusor.next).nil?
        messages
      end # read(bytes)

      def write(msg)
        #puts "#{Process.pid} #{Time.new.to_i} #{self}.write ====>\n#{msg}\n"
        @collection.save({"msg" => msg})
      end # write(msg)
      
      def select(timeout = 1)
        #return IO.select([s = @db.connection.checkout_reader], nil, nil, timeout).tap { @db.connection.checkin_reader(s)}
        return (@cursor.count > 0 ? true : nil) if timeout == 0
        
        if timeout.nil?
          sleep 0.01 while @cusor.count < 1
          return true
        end # timeout.nil?
        
        waited = 0.00
        while waited < timeout
          return true if @cursor.count > 0
          waited += 0.001
          sleep 0.0001
        end # waited < timeout
      end # select(timeout = 1)
      
      # Close the mailbox and don't receive any messages from it
      # @return [String] the address of the mailbox
      # @todo rely on inheritence instead
      def unbind
        @mongo.close
        @address.tap{ @address = "" }
      end # unbind
      
      
    private
      
      def connect_mongo(url)
        #return @collection unless @collection.nil?
        url         = "mongodb://127.0.0.1:27017" if url.nil?
        url         = URI.parse(url)
        
        n,db,col    = url.path.split("/",3)
        db          = "yaram" if db.nil? || db.empty?
        col         = UUID.generate if col.nil? || col.empty?
        url.path    = "/#{db}/#{col}"
        
        @url        = url
        @address    = @url.to_s
        
        @mongo       = Mongo::Connection.new(url.host, url.port)
        @db          = @mongo.db(db)
        @collection = @db.collection_names.include?(col) ? @db.collection(col) : @db.create_collection(col, :capped => true, :max => 2000)
      end # connect_mongo(url)
    end # class::Mailbox < ::Yaram::Mailbox
  end # module::Mongodb
end # module::Yaram
