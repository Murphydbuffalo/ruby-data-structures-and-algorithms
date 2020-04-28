require "rspec"
require "./resizing_array.rb"

describe ResizingArray do
  it "pushes and pops items from its tail" do
    expect(subject.push(1)).to be 1
    expect(subject.push(2)).to be 2
    expect(subject.size).to be 2

    expect(subject.pop).to be 2
    expect(subject.pop).to be 1
    expect(subject.size).to be 0
    expect(subject.pop).to be nil
  end

  it "shifts and unshifts items from its head" do
    expect(subject.unshift(2)).to be 2
    expect(subject.unshift(1)).to be 1
    expect(subject.size).to be 2

    expect(subject.shift).to be 1
    expect(subject.shift).to be 2
    expect(subject.size).to be 0
    expect(subject.shift).to be nil
  end

  it "reads, inserts and deletes items from arbitrary indexes" do
    subject.push("c")
    expect(subject.insert_at(0, "a")).to eq "a"
    expect(subject.insert_at(1, "b")).to eq "b"
    expect(subject.insert_at(3, "d")).to eq "d"

    expect(subject[0]).to eq "a"
    expect(subject[1]).to eq "b"
    expect(subject[2]).to eq "c"
    expect(subject[3]).to eq "d"

    %w[a b c d].each do |letter|
      expect(String).to receive(:try_convert).with(letter)
    end

    subject.each do |letter|
      String.try_convert(letter)
    end

    expect(subject.delete_at(1)).to eq "b"

    expect(subject[0]).to eq "a"
    expect(subject[1]).to eq "c"
    expect(subject[2]).to eq "d"

    %w[a c d].each do |letter|
      expect(String).to receive(:try_convert).with(letter)
    end

    subject.each do |letter|
      String.try_convert(letter)
    end
  end

  it "raises an error if you attempt to access an index out of range" do
    array = described_class.new(1, 2, 3)
    expect { array[4] }.to raise_error(
      ArgumentError,
      "index cannot be negative or greater than the current size of the array"
    )
    expect { array[-1] }.to raise_error(
      ArgumentError,
      "index cannot be negative or greater than the current size of the array"
    )

    expect { array.insert_at(4, "hi") }.to raise_error(
      ArgumentError,
      "index cannot be negative or greater than the current size of the array"
    )

    expect { array.insert_at(30, "bye") } .to raise_error(
      ArgumentError,
      "index cannot be negative or greater than the current size of the array"
    )

    expect { array.delete_at(4) }.to raise_error(
      ArgumentError,
      "index cannot be negative or greater than the current size of the array"
    )
  end

  it "has #size and #capacity" do
    expect(subject.size).to be 0
    expect(subject.capacity).to be 10
  end 

  it "increases capacity if it is full" do
    10.times do |n|
      subject.push("Item #{n}")
    end

    expect(subject.size).to be 10
    expect(subject.capacity).to be 15

    5.times do |n|
      subject.push("Item #{10 + n}")
    end

    expect(subject.size).to be 15
    expect(subject.capacity).to be 22

    7.times do |n|
      subject.push("Item #{15 + n}")
    end

    expect(subject.size).to be 22
    expect(subject.capacity).to be 33
  end

  it "decreases capacity if it has lots of unused space" do
    10.times do |n|
      subject.push("Item #{n}")
    end

    expect(subject.size).to be 10
    expect(subject.capacity).to be 15

    5.times do |n|
      subject.pop
    end

    expect(subject.size).to be 5
    expect(subject.capacity).to be 15

    subject.pop
    expect(subject.size).to be 4
    expect(subject.capacity).to be 7

    subject.pop
    expect(subject.size).to be 3
    expect(subject.capacity).to be 7

    subject.pop
    expect(subject.size).to be 2
    expect(subject.capacity).to be 3
  end

  it "accepts a list of initial items" do
    array = described_class.new("a", "b", "c")
    expect(array.size).to be 3
    expect(array.capacity).to be 10

    expect(array.pop).to eq "c"
    expect(array.size).to be 2

    expect(array.pop).to eq "b"
    expect(array.size).to be 1

    expect(array.pop).to eq "a"
    expect(array.size).to be 0
  end

  describe "#each" do
    it "executes a block with each item as an argument" do
      array = described_class.new("a", "b", "c")
      %w[a b c].each do |item|
        # Call some arbitrary method with each item to assert
        # that ResizingArray#each works
        expect(String).to receive(:try_convert).with(item)
      end

      array.each do |item|
        String.try_convert(item)
      end
    end
  end

  describe "#map" do
    it "returns a transformed version of itself based on a block" do
      array = described_class.new("a", "b", "c")
      new_array = array.map { |item| item.upcase }
      expect(new_array.size).to be 3
      expect(new_array[0]).to eq("A")
      expect(new_array[1]).to eq("B")
      expect(new_array[2]).to eq("C")
    end
  end

  describe "#select" do
    it "returns a filtered version of itself based on a block" do
      array = described_class.new(5, 10, 15, 20, 25)
      new_array = array.select { |item| item > 12 }
      expect(new_array.size).to be 3
      expect(new_array[0]).to eq(15)
      expect(new_array[1]).to eq(20)
      expect(new_array[2]).to eq(25)
    end
  end
end
