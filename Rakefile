require "bundler/gem_tasks"

require 'fileutils'
require 'rake/testtask'
require 'rake/clean'

Rake::TestTask.new(:test) do |t|
  # To run test for only one file (or file path pattern)
  #  $ bundle exec rake test TEST=test/test_specified_path.rb
  #  $ bundle exec rake test TEST=test/test_*.rb
  t.libs << "test"
  t.test_files = Dir["test/**/test_*.rb"].sort
  t.verbose = true
  t.warning = true
  t.ruby_opts = ["-Eascii-8bit:ascii-8bit"]
end

task :default => :test
