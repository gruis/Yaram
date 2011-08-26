require File.expand_path("../lib/yaram/crypto/version", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                        = "yaram-crypto"
  s.version                     = Yaram::Crypto::VERSION
  s.platform                    = ::Gem::Platform::RUBY
  s.authors                     = ["Caleb Crane"]
  s.email                       = ["yaram-crypto@simulacre.org"]
  s.homepage                    = "http://www.simulacre.org/yaram-crypto"
  s.summary                     = "yaram-crypto provides encryption for Yaram messages"
  s.description                 = ""
  s.required_rubygems_version   = ">= 1.3.6"
  s.rubyforge_project           = "yaram-crypto"
  s.files                       = Dir["lib/**/*.rb", "bin/*", "*.md"]
  s.require_paths               = ['lib']
  s.executables               = Dir["bin/*"].map{|f| f.split("/")[-1] }

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"

  s.add_dependency "yaram"
  s.add_dependency "fast-aes", "~> 0.1.1"
  s.add_dependency "highline"
end
