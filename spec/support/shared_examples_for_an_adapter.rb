shared_examples_for "an Adapter" do
  it { should respond_to :call }
  it { should respond_to :connect }

  describe "#call" do
    it_behaves_like "a Rack application"
  end

  describe "#connect" do
    it "returns a Rack::Response" do
      subject.connect(Rack::Request.new(env)).should be_a Rack::Response
    end
  end


end