shared_examples_for "a URI" do
  it { uri.should respond_to(:path) }
  it { uri.should respond_to(:query) }
  it { uri.should respond_to(:host) }
  it { uri.should respond_to(:port) }
  it { uri.should respond_to(:inferred_port) }
  it { uri.should respond_to(:request_uri) }
  it { uri.should respond_to(:scheme) }
end