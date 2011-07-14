source "http://rubygems.org"
source "http://dev.kvh-ms.lan:8808/"
require "rbconfig"

# Will automatically pull in this gem and all its
# dependencies specified in the gemspec
gem "yaram", :path => File.expand_path("..", __FILE__)

group :default do
  gem "ox", "~>1.2.2" # < 1.2.2 had a GC error
end # :default do 

gem "thor"
gem "changelog"
gem "yard"

group :test do
  gem 'rspec', '~>2.2.0'
  gem 'simplecov'
  gem "autotest", '4.4.6'
  if Config::CONFIG["host_vendor"] == "apple"
    gem "autotest-growl"
    gem "autotest-fsevent"  
  end
end