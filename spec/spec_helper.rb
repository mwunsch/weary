require 'weary'
require 'webmock/rspec'
require 'multi_json'

Dir['./spec/support/**/*.rb'].each {|f| require f }

WebMock.disable_net_connect!
