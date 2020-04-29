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

  it "accepts a list of key-value pairs at initialization"
  it "rehashes all entries when the ratio of entries to buckets it too high"
end
