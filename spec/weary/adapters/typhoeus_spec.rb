require 'spec_helper'

begin
  describe Weary::Adapter::Typhoeus do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      @request = Weary::Request.new @url
    end

    describe "class methods" do
      it_behaves_like "an Adapter" do
        before do
          stub_request(:get, @url).
             to_return(:status => 200, :body => "", :headers => {})
        end

        subject { described_class }
        let(:env) { @request.env }
      end

      describe ".call" do
        it "performs the request through the connect method" do
          described_class.stub(:connect) { Rack::Response.new("", 200, {})}
          described_class.should_receive :connect
          described_class.call(@request.env)
        end
      end

      describe ".url_for" do
        it "cracks the Rack::Request open and returns a scheme + fqdn + port" do
          req = Rack::Request.new(@request.env)
          url = described_class.url_for(req)
          url.should == @url
        end

        it "correctly uses the right scheme" do
          input_url = "https://github.com/hypomodern"
          request = Weary::Request.new input_url
          req = Rack::Request.new(request.env)
          output_url = described_class.url_for(req)
          output_url.should == input_url
        end

        it "correctly uses the right port" do
          input_url = "http://mytestserver.com:9292/v1/foo"
          request = Weary::Request.new input_url
          req = Rack::Request.new(request.env)
          output_url = described_class.url_for(req)
          output_url.should == input_url
        end
      end
    end

    describe "#connect" do
      it "calls the class method `.connect`" do
        described_class.stub(:connect) { [200, {'Content-Type' => 'text/plain'}, [""]] }
        described_class.should_receive(:connect)
        described_class.new.connect(Rack::Request.new(@request.env))
      end
    end

    describe "#call" do
      it "uses the overriden `#connect` method" do
        instance = described_class.new
        instance.stub(:connect) { Rack::Response.new [""], 501, {"Content-Type" => "text/plain"} }
        instance.should_receive(:connect)
        instance.call(@request.env)
      end
    end

    it_behaves_like "an Adapter" do
      before do
        stub_request(:get, @url).
           to_return(:status => 200, :body => "", :headers => {})
      end

      subject { described_class }
      let(:env) { @request.env }
    end

  end

rescue LoadError => e
  warn <<-MSG
    [warn] Received a LoadError when attempting to load the Typhoeus adapter,
    and skipping the specs.

    #{e.message}

    Make sure Typhoeus is in the $LOAD_PATH.
  MSG
end