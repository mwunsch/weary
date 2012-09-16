require 'weary'
require 'webmock/rspec'
require 'multi_json'

Dir['./spec/support/**/*.rb'].each {|f| require f }

WebMock.disable_net_connect!

RSpec.configure do |c|
  c.filter_run_excluding :exclude_from_rbx => !!(RUBY_ENGINE =~ /rbx/)
end