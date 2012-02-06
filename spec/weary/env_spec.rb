require 'spec_helper'

describe Weary::Env do
  describe "#env" do
    it_behaves_like "a Rack env" do
      subject do
        req = Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary")
        described_class.new(req).env
      end
    end
  end
end