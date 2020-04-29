require 'rspec'
require './hash_code'

describe HashCode do
  let(:test_values) do
    [
      "foo",
      :baz,
      14,
      27.65,
      [1,2,3],
      { yee: "haw!" },
      Struct.new(:hello).new("testing 1,2,3")
    ]
  end

  it "returns an integer" do
    test_values.each do |val|
      expect(described_class.for(val)).to be_a Integer
    end
  end

  it "always returns the same code for a given value" do
    codes = test_values.map { |val| described_class.for(val) }

    30.times do
      expect(codes).to eq test_values.map { |val| described_class.for(val) }
    end
  end

  # This isn't true strictly speaking. You can and will have collisions with
  # certain values. But basically we want to have a high degree of confidence
  # that collisions will be rare.
  it "produces codes that are unique" do
    codes = 1.upto(10_000).map do |n|
      described_class.for(n)
    end

    expect(codes.uniq).to eq codes
  end
end
