shared_examples_for "a Rack application" do
  it { should respond_to :call }

  it "takes one argument, the environment" do
    method = if subject.is_a? Module
      subject.method :call
    else
      subject.class.instance_method :call
    end
    method.arity.should eq 1
  end

  it "returns an Array" do
    subject.call(env).should be_an Array
  end

  it "returns with three arguments" do
    subject.call(env).length.should be 3
  end

  it "passes Rack::Lint" do
    rack_defaults = {
      'rack.version'      => Rack::VERSION,
      'rack.errors'       => $stderr,
      'rack.multithread'  => true,
      'rack.multiprocess' => false,
      'rack.run_once'     => false
    }
    lint = Rack::Lint.new subject
    expect { lint.call(rack_defaults.update(env)) }.to_not raise_error Rack::Lint::LintError
  end

  describe "the status" do
    let(:status) { subject.call(env).first }

    it "is greater than or equal to 100 when parsed as an integer" do
      status.to_i.should be >= 100
    end
  end

  describe "the headers" do
    let(:response) { subject.call(env) }
    let(:headers) { response[1] }

    it { headers.should respond_to :each }

    it "yields values of key and value" do
      headers.should be_all {|key, value| !key.nil? && !value.nil? }
    end

    it "contains keys of Strings" do
      headers.keys.should be_all {|key| key.kind_of? String }
    end

    it "does not contain a 'Status' key" do
      headers.keys.map(&:downcase).should_not include 'status'
    end

    it "contains values of Strings" do
      headers.values.should be_all {|value| value.kind_of? String }
    end
  end

  describe "the body" do
    let(:body) { subject.call(env).last }

    it { body.should respond_to :each }

    it "yields only String values" do
      map = []
      body.each {|string| map << string }
      # We do this strange mapping, since the only requirement
      # of the body is it responds to :each.
      # This allows us to use Array predicates
      map.should be_all {|i| i.kind_of? String }
    end
  end

end
