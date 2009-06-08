require 'rubygems'
require 'spec/rake/spectask'

task :default => :spec

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "weary"
    gemspec.summary = "A little DSL for consuming RESTful web services"
    gemspec.email = "mark@markwunsch.com"
    gemspec.homepage = "http://github.com/mwunsch/weary"
    gemspec.description = "The Weary need REST: a tiny DSL that makes the consumption of RESTful web services simple."
    gemspec.authors = "Mark Wunsch"
    gemspec.has_rdoc = false
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"  
end



Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color','--format nested']
end