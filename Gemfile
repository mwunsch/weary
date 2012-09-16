source "http://rubygems.org"

gemspec

gem "rake", "~> 0.9.2"
gem "excon"
if !(RUBY_ENGINE =~ /rbx/)
  gem "typhoeus"
end

group :test do
  gem "rspec", "~> 2.11.0"
  gem "webmock", "~> 1.8.10"
end

group :doc do
  gem "yard", "~> 0.7.5"
  gem "yard-tomdoc", "~> 0.4.0"
end

platforms :jruby do
  gem "jruby-openssl"
end
