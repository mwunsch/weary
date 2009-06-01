require 'rubygems'
require 'spec/rake/spectask'

task :default => :spec
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color','--format nested']
end