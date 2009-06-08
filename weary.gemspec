# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{weary}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mark Wunsch"]
  s.date = %q{2009-06-08}
  s.description = %q{The Weary need REST: a tiny DSL that makes the consumption of RESTful web services simple.}
  s.email = %q{mark@markwunsch.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    "LICENSE",
     "README.md",
     "Rakefile",
     "VERSION",
     "lib/weary.rb",
     "lib/weary/exceptions.rb",
     "lib/weary/request.rb",
     "lib/weary/resource.rb",
     "lib/weary/response.rb",
     "spec/weary/request_spec.rb",
     "spec/weary_spec.rb"
  ]
  s.homepage = %q{http://github.com/mwunsch/weary}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A little DSL for consuming RESTful web services}
  s.test_files = [
    "spec/weary/request_spec.rb",
     "spec/weary_spec.rb",
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
