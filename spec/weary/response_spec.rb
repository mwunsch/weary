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

  describe "#parse" do
    before do
      @body = {
        :sales => [
          :name => "Spring: Just Around the Corner",
          :sale => "https://api.gilt.com/v1/sales/men/spring-just-arou-108/detail.json",
          :sale_key => "spring-just-arou-108",
          :store => "men",
          :description => "Were you aware that there are seasons? Spring will start soon so etc",
          :begins => "2012-02-09T17:00:00Z"
        ]
      }
    end

    it "parses json out of the response" do
      json = MultiJson.encode @body
      response = Weary::Response.new json, 200, {'Content-Type' => 'application/json'}
      response.parse.should eql MultiJson.decode(json)
    end

    it "raises an error if the content type is unknown" do
      response = Weary::Response.new "<lolxml />", 200, {'Content-Type' => 'application/xml'}
      expect { response.parse }.to raise_error
    end

    it "raises an error if there is no body" do
      response = Weary::Response.new "", 404, {'Content-Type' => 'text/plain'}
      expect { response.parse }.to raise_error
    end

    it "receives an optional block for custom parsing" do
      message = "Hello, world."
      dump = Marshal.dump(message)
      response = Weary::Response.new dump, 200, {'Content-Type' => 'text/plain'}
      parsed = response.parse do |body, content_type|
        Marshal.load(body)
      end
      parsed.should eql message
    end
  end
end