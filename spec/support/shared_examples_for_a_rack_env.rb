shared_examples_for "a Rack env" do
  # From the Rack spec:
  # http://rack.rubyforge.org/doc/SPEC.html
  it { should be_an_instance_of Hash }
  it { should have_key "REQUEST_METHOD"}
  it "does not have an empty value for REQUEST_METHOD" do
    subject["REQUEST_METHOD"].should_not be_empty
  end
  it { should have_key "SCRIPT_NAME"}
  it { should have_key "PATH_INFO"}
  it { should have_key "QUERY_STRING"}
  it { should have_key "SERVER_NAME"}
  it { should have_key "SERVER_PORT"}
end