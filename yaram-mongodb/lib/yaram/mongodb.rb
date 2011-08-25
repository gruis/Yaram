require "mongo"
require "bson"

require "yaram/mongodb/version"
require "yaram/mailbox"

module Yaram
  module Mongodb

    class Mailbox < ::Yaram::Mailbox
      def initialize(address = nil)
        @address = address
      end # initialize(url = nil)
      
      def bind(addr = nil)
        close if connected? || bound?
        addr ||= @address
        @cursor = Mongo::Cursor.new(@io = connect_mongo(addr), :tailable => true, :order => [['$natural', 1]], :capped => true, :max => 20) # needs a wait data option
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
        while !(d = @cursor.next)
          sleep 0.1
        end # !(d = @cursor.next)
        puts "d::::#{d}"
        d["msg"]
      end # read(bytes)

      def write(msg)
        @collection.insert({"msg" => msg})
      end # write(msg)
      
      def select(timeout = 1)
        @collection.count > 0 ? true : nil
      end
      
      # Close the mailbox and don't receive any messages from it
      # @return [String] the address of the mailbox
      def unbind
        #@io.close
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
        #@mongo      = Mongo::Connection.from_uri(@address)
        @collection = @mongo.db(db).create_collection(col, :capped => true, :max => 2000)
      end # connect_mongo(url)
    end # class::Mailbox < ::Yaram::Mailbox
  end # module::Mongodb
end # module::Yaram
