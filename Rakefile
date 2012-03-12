require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require 'yard'

task :default => :spec

RSpec::Core::RakeTask.new(:spec)

# The state of yard-tomdoc isn't so great right now
YARD::Rake::YardocTask.new