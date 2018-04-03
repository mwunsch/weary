source "http://rubygems.org"

gemspec

gem "rake", "~> 12.3.1"
gem "excon"

group :test do
  gem "rspec", "~> 3.7"
  gem "webmock", "~> 3.3"
end

group :doc do
  gem "yard", "~> 0.8"
  gem "yard-tomdoc", "~> 0.7"
end

platforms :jruby do
  gem "jruby-openssl"
end

platforms :mri, :jruby do
  gem "typhoeus", "~> 0.5"
end

platforms :rbx do
  gem "rubysl", "~> 2.0"
end
