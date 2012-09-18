source "http://rubygems.org"

gemspec

gem "rake", "~> 0.9.2"
gem "excon"

group :test do
  gem "rspec", "~> 2.11.0"
  gem "webmock", "~> 1.8.10"
end

group :doc do
  gem "yard", "~> 0.8.2"
  gem "yard-tomdoc", "~> 0.5.0"
end

platforms :jruby do
  gem "jruby-openssl"
end

platforms :mri, :jruby do
  gem "typhoeus"
end
