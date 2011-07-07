require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require "yaml"
require "rspec/core/rake_task"
require "yard"

desc 'Default: run unit tests.'
task :default => :test

RSpec::Core::RakeTask.new :spec do |s|
  s.skip_bundler = false
end

namespace :spec do
  desc "Run specs with terse output"
  RSpec::Core::RakeTask.new("terse") do |s|
    s.skip_bundler = false
    s.rspec_opts   = ["--colour", "--format progress"]
  end
  desc "Run specs and save output for review"
  RSpec::Core::RakeTask.new("report") do |s|
    s.skip_bundler = false
    s.rspec_opts   = ["--colour", "--format html -o spec/results.html"]
  end  
end

desc "Benchmark the  plugin."
Rake::TestTask.new(:benchmark) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_benchmark.rb'
  t.verbose = true
end

desc 'Test the  plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.options = "-v"
end

desc 'Generate rdoc documentation for the yaram plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Yaram'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Generate YARD documentation for the  plugin.'
YARD::Rake::YardocTask.new do |t|
  # t.files   = Dir['lib/**/*.rb', "bin/*"]   # optional
  # t.options = ['--any', '--extra', '--opts'] # optional
end

