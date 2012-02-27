require 'spec_helper'

describe Weary::Response do
  describe "#status" do
    subject { Weary::Response.new [""], 200, {'Content-Type' => 'text/plain'} }
    it "returns a response code" do
      subject.status.should eql 200
    end
  end

  describe "#header" do
    subject { Weary::Response.new [""], 200, {'Content-Type' => 'text/plain'} }
    it "returns the headers as a hash" do
      subject.header.should have_key 'Content-Type'
    end
  end

  describe "#body" do
    subject { Weary::Response.new ["Hi"], 200, {'Content-Type' => 'text/plain'} }
    it "returns the body, compacted" do
      subject.body.should eql "Hi"
    end
  end

  describe "#each" do
    subject { Weary::Response.new ["Hi"], 200, {'Content-Type' => 'text/plain'} }
    it "calls #each on the body" do
      iterated = false
      subject.each {|body| iterated = body.downcase.to_sym }
      iterated.should eql :hi
    end
  end

  describe "#finish" do
    subject { Weary::Response.new [""], 200, {'Content-Type' => 'text/plain'} }
    it "provides a Rack tuple" do
      subject.finish.length.should be 3
    end
  end

  describe "#success?" do
    subject { Weary::Response.new ["Hi"], 200, {'Content-Type' => 'text/plain'} }
    it "returns true if the request was successful" do
      subject.success?.should be true
    end
  end

  describe "#redirected?" do
    subject { Weary::Response.new ["Hi"], 301, {'Content-Type' => 'text/plain'} }
    it "returns true if the request was redirected" do
      subject.redirected?.should be true
    end
  end

  describe "#length" do
    subject { Weary::Response.new ["Hi"], 301, {'Content-Type' => 'text/plain'} }
    it "returns the content-length" do
      subject.length.should eql subject.header['Content-Length'].to_i
    end
  end

  describe "#call" do
    it_behaves_like "a Rack application" do
      subject { Weary::Response.new [""], 200, {'Content-Type' => 'text/plain'}}
      let(:env) { Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary").env }
    end
  end

end