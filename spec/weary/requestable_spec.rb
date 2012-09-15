require 'spec_helper'

describe Weary::Requestable do

  it_behaves_like "a Requestable" do
    subject { Class.new { include Weary::Requestable }.new }
  end

end