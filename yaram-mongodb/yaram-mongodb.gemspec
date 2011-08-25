require File.expand_path("../lib/yaram/mongodb/version", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                        = "yaram-mongodb"
  s.version                     = Yaram::Mongodb::VERSION
  s.platform                    = ::Gem::Platform::RUBY
  s.authors                     = ["caleb"]
  s.email                       = ["yaram-mongodb@simulacre.org"]
  s.homepage                    = "http://www.simulacre.org/yaram-mongodb"
  s.summary                     = "yaram-mongodb provides yaram mailboxes over mongoDB"
  s.description                 = ""
  s.required_rubygems_version   = ">= 1.3.6"
  s.rubyforge_project           = "yaram-mongodb"
  s.files                       = Dir["lib/**/*.rb", "bin/*", "*.md"]
  s.require_paths               = ['lib']
  s.executables               = Dir["bin/*"].map{|f| f.split("/")[-1] }

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"

  s.add_dependency "mongo", "~>1.3.1"
  s.add_dependency "bson_ext", "~>1.3.1"
end
