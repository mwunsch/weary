require 'rubygems'
require 'spec/rake/spectask'

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'weary'
  rdoc.main     = 'README.md'
  rdoc.rdoc_files.include('README.*', 'lib/**/*.rb', 'LICENSE')
  rdoc.options  << '--inline-source'
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "weary"
    gemspec.rubyforge_project = "weary"
    gemspec.summary = "A little DSL for consuming RESTful web services"
    gemspec.email = "mark@markwunsch.com"
    gemspec.homepage = "http://github.com/mwunsch/weary"
    gemspec.description = "The Weary need REST: a tiny DSL that makes the consumption of RESTful web services simple."
    gemspec.authors = "Mark Wunsch"
    gemspec.add_dependency('crack', '>= 0.1.2')
    gemspec.add_dependency('oauth', '>= 0.3.5')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"  
end

begin
  require 'rake/contrib/sshpublisher'
  namespace :rubyforge do

    desc "Release gem and RDoc documentation to RubyForge"
    task :release => ["rubyforge:release:gem", "rubyforge:release:docs"]

    namespace :release do
      desc "Publish RDoc to RubyForge."
      task :docs => [:rdoc] do
        config = YAML.load(
            File.read(File.expand_path('~/.rubyforge/user-config.yml'))
        )

        host = "#{config['username']}@rubyforge.org"
        remote_dir = "/var/www/gforge-projects/weary/"
        local_dir = 'doc'

        Rake::SshDirPublisher.new(host, remote_dir, local_dir).upload
      end
    end
  end
rescue LoadError
  puts "Rake SshDirPublisher is unavailable or your rubyforge environment is not configured."
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r weary.rb"
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color','--format nested']
end