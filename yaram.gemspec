require File.expand_path("../lib/yaram/version", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                        = "yaram"
  s.version                     = Yaram::VERSION
  s.platform                    = ::Gem::Platform::RUBY
  s.authors                     = ["Caleb Crane"]
  s.email                       = ["yaram@simulacre.org"]
  s.homepage                    = "http://www.simulacre.org/yaram"
  s.summary                     = "Yaram is Yet Another Ruby Actor Model"
  s.description                 = ""
  s.required_rubygems_version   = ">= 1.3.6"
  s.rubyforge_project           = "yaram"
  s.files                       = Dir["lib/**/*.rb", "bin/*", "*.md"]
  s.require_paths               = ['lib']
  s.executables               = Dir["bin/*"].map{|f| f.split("/")[-1] }

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"

  # s.add_dependency "otherproject", "~> 1.2"
  s.add_dependency "uuid"
end
