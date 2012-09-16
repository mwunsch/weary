require 'spec_helper'
require 'weary/deferred'

describe Weary::Deferred do
  before :all do
    @struct = Struct.new "Deferred", :response
  end

  before do
    @request = Weary::Request.new "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    adapter = Class.new { include Weary::Adapter }
    @request.adapter adapter
  end

  describe "::new" do
    it "creates a new deffered proxy object around a model" do
      deferred = described_class.new @request.perform, @struct
      deferred.should be_instance_of @struct
    end

    it "with a factory method" do
      deferred = described_class.new @request.perform, @struct, lambda {|model, response| response.status }
      deferred.should eql 501
    end
  end

  describe "#complete?" do
    it "is true when the target is ready" do
      deferred = described_class.new @request.perform, @struct
      deferred.inspect
      deferred.complete?.should be_true
    end
  end

end