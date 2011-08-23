require "thread" # why?

module Yaram
  class << self
    attr_accessor :encoder
  end # << self
end # module::Yaram

require "yaram/version"
require "yaram/encoder"
require "yaram/generic-encoder"
require "yaram/ext/yaram"
require "yaram/error"
require "yaram/message"
require "yaram/reply"
require "yaram/session"
require "yaram/actor"
require "yaram/mailbox"
