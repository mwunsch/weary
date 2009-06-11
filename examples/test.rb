require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')
require 'pp'

class Test
  extend Weary
  
  declare_resource "show" do |r|
    r.authenticates = true
    r.requires = "foo", "bar"
    r.with = [:guffaw]
  end

end