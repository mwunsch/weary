begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

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
    gemspec.description = "A tiny DSL that makes the consumption of RESTful web services simple."
    gemspec.authors = "Mark Wunsch"
    gemspec.add_dependency 'crack', '>= 0.1.2'
    gemspec.add_dependency 'oauth', '>= 0.3.5'
    gemspec.add_development_dependency 'bundler', ">= 0.9.7"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available.  Install it with: gem install jeweler"
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r weary.rb"
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color','--format nested']
end