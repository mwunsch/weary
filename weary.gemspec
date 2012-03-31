# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "weary/version"

Gem::Specification.new do |s|
  s.name = %q{weary}
  s.version = "#{Weary::VERSION}"
  s.authors = ["Mark Wunsch"]
  s.email = %q{mark@markwunsch.com}
  s.summary = %q{A framework and DSL for the consumption of RESTful web services.}
  s.description = %q{A framework and DSL to Ruby clients to RESTful web services. }
  s.homepage = %q{http://github.com/mwunsch/weary}
  s.rubyforge_project = %q{weary}

  s.files = `git ls-files`.split "\n"
  s.test_files = `git ls-files -- {spec,examples}/*`.split "\n"

  s.require_paths = ['lib']

  s.add_runtime_dependency "rack", "~> 1.4.0"
  s.add_runtime_dependency "addressable", "~> 2.2.6"
  s.add_runtime_dependency "promise", "~> 0.3.0"
  s.add_runtime_dependency "simple_oauth", "~> 0.1.5"
  s.add_runtime_dependency "multi_json", "~> 1.1.0"
  s.add_development_dependency "rspec", "~> 2.8.0"
  s.add_development_dependency "webmock", "~> 1.8.0"
end
