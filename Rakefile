require 'fileutils'

MRUBY_VERSION="1.2.0"

file :mruby do
  #sh "git clone --depth=1 https://github.com/mruby/mruby"
  sh "curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/#{MRUBY_VERSION}.tar.gz -s -o - | tar zxf -"
  FileUtils.mv("mruby-#{MRUBY_VERSION}", "mruby")
end

APP_NAME=ENV["APP_NAME"] || "msgpack-inspect"
APP_ROOT=ENV["APP_ROOT"] || Dir.pwd
# avoid redefining constants in mruby Rakefile
mruby_root=File.expand_path(ENV["MRUBY_ROOT"] || "#{APP_ROOT}/mruby")
mruby_config=File.expand_path(ENV["MRUBY_CONFIG"] || "build_config.rb")
ENV['MRUBY_ROOT'] = mruby_root
ENV['MRUBY_CONFIG'] = mruby_config
Rake::Task[:mruby].invoke unless Dir.exist?(mruby_root)
load "#{mruby_root}/Rakefile"
Rake::Task['test'].clear # to clear test task of mruby/Rakefile

desc "compile binary"
task :compile => [:all] do
  Dir.chdir(mruby_root) do
    MRuby.each_target do |target|
      `#{target.cc.command} --version`
      abort("Command #{target.cc.command} for #{target.name} is missing.") unless $?.success?
    end
    %W(#{mruby_root}/build/x86_64-pc-linux-gnu/bin/#{APP_NAME} #{mruby_root}/build/i686-pc-linux-gnu/#{APP_NAME}).each do |bin|
      sh "strip --strip-unneeded #{bin}" if File.exist?(bin)
    end
  end
end

desc "cleanup"
task :clean do
  Dir.chdir(mruby_root) do
    sh "rake deep_clean"
  end
end

desc "generate a release tarball"
task :release => :compile do
  require 'tmpdir'

  Dir.chdir(mruby_root) do
  # since we're in the mruby/
  release_dir  = "releases/v#{APP_VERSION}"
  release_path = Dir.pwd + "/../#{release_dir}"
  app_name     = "#{APP_NAME}-#{APP_VERSION}"
  FileUtils.mkdir_p(release_path)

  Dir.mktmpdir do |tmp_dir|
    Dir.chdir(tmp_dir) do
      MRuby.each_target do |target|
        next if name == "host"

        arch = name
        bin  = "#{build_dir}/bin/#{exefile(APP_NAME)}"
        FileUtils.mkdir_p(name)
        FileUtils.cp(bin, name)

        Dir.chdir(arch) do
          arch_release = "#{app_name}-#{arch}"
          puts "current dir #{Dir.pwd}"
          puts "Writing #{release_path}/#{arch_release}.tgz"
          `tar czf #{release_path}/#{arch_release}.tgz *`
        end
      end

      puts "Writing #{release_dir}/#{app_name}.tgz"
      `tar czf #{release_path}/#{app_name}.tgz *`
    end
  end
  end
end

namespace :local do
  desc "show version"
  task :version do
    puts "#{APP_NAME} #{APP_VERSION}"
  end
end

def is_in_a_docker_container?
  `test -f /proc/self/cgroup && grep -q docker /proc/self/cgroup`
  $?.success?
end

Rake.application.tasks.each do |task|
  next if ENV["MRUBY_CLI_LOCAL"]
  unless task.name.start_with?("local:") || task.name == 'test'
    # Inspired by rake-hooks
    # https://github.com/guillermo/rake-hooks
    old_task = Rake.application.instance_variable_get('@tasks').delete(task.name)
    desc old_task.full_comment
    task old_task.name => old_task.prerequisites do
      abort("Not running in docker, you should type \"docker-compose run <task>\".")         unless is_in_a_docker_container?
      old_task.invoke
    end
  end
end

if is_in_a_docker_container?
  load File.join(File.expand_path(File.dirname(__FILE__)), "mrbgem.rake")

  current_gem = MRuby::Gem.current
  app_version = MRuby::Gem.current.version
  APP_VERSION = (app_version.nil? || app_version.empty?) ? "unknown" : app_version

  task default: :compile
else
  Rake::Task['release'].clear # to clear release tasks to create mruby binary
  require "bundler/gem_tasks"
  require 'rake/testtask'
  # require 'rake/clean'

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
  task default: [:test, :release]
end

