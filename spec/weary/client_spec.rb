require 'spec_helper'

describe Weary::Client do
  describe "::resource" do
    subject { Class.new(Weary::Client) }

    it "defines a user resource" do
      resource = subject.resource :show, "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource.should be_a Weary::Resource
    end
  end
end