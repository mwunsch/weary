require 'weary'
require 'webmock/rspec'
require 'multi_json'

Dir['./spec/support/**/*.rb'].each {|f| require f }

WebMock.disable_net_connect!

def rbx?
  defined? RUBY_ENGINE and 'rbx' == RUBY_ENGINE
end

RSpec.configure do |c|
  c.filter_run_excluding :exclude_from_rbx => rbx?
end

