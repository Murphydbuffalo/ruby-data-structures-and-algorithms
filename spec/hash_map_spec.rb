require 'rspec'
require './hash_map'

describe HashMap do
  it "reads and writes values by key" do
    expect(subject[:foo] = "bar").to eq "bar"
    subject["baz"] = "bat"
    subject[12] = "honky tonk"
    subject[[1,2,3]] = "oh lord!"

    expect(subject[:foo]).to eq "bar"
    expect(subject["baz"]).to eq "bat"
    expect(subject[12]).to eq "honky tonk"
    expect(subject[[1,2,3]]).to eq "oh lord!"
  end

  it "lists all keys and values" do
    subject[:foo] = "bar"
    subject["baz"] = "bat"
    subject[12] = "honky tonk"
    subject[[1,2,3]] = "oh lord!"


    expect(subject.keys).to match_array([:foo, "baz", 12, [1,2,3]])
    expect(subject.values).to match_array(["bar", "bat", "honky tonk", "oh lord!"])
  end

  it "accepts a list of key-value pairs at initialization" do
    h = described_class.new([[:foo, "bar"], [:baz, "bat"]])
    expect(h[:foo]).to eq "bar"
    expect(h[:baz]).to eq "bat"
  end

  it "rehashes all entries when the ratio of entries to buckets it too high" do
    subject = described_class.new
    expect(subject).to receive(:rehash_all).and_call_original

    8.times do |n|
      subject[n.to_s] = n    
    end

    expect(subject.send(:array).capacity).to be >= 16

    8.times do |n|
      expect(subject[n.to_s]).to be n    
    end
  end
end
