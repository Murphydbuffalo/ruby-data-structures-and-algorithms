require "rspec"
require "./linked_list"

describe LinkedList do
  it "appends and prepends items" do
    subject.append("A")
    expect(subject.tail.value). to eq "A"
    expect(subject.head.value). to eq "A"

    subject.append("B")
    expect(subject.tail.value). to eq "B"
    expect(subject.head.value). to eq "A"

    subject.prepend("Z")
    expect(subject.tail.value). to eq "B"
    expect(subject.head.value). to eq "Z"
  end

  it "inserts items at arbitrary locations" do
    subject.append("A")
    subject.append("B")

    subject.insert("Z", after: subject.head)
    expect(subject.tail.value). to eq "B"
    expect(subject.head.value). to eq "A"
    expect(subject.head.next_node.value).to eq "Z"
    expect(subject.tail.prev_node.value).to eq "Z"
  end

  it "finds items by value" do
    subject.append("A")
    subject.append("B")
    subject.append("C")

    node = subject.find("B")
    expect(node.value). to eq "B"
    expect(node.next_node.value).to eq "C"
    expect(node.prev_node.value).to eq "A"
  end

  it "finds items by evaluating a block" do
    subject.append("A")
    subject.append("Well I certainly do enjoy a good scotch!")
    subject.append("C")

    node = subject.find { |val| val.include?("good scotch") }
    expect(node.value). to eq "Well I certainly do enjoy a good scotch!"
    expect(node.next_node.value).to eq "C"
    expect(node.prev_node.value).to eq "A"
  end


  it "iterates from one item to the next in either direction" do
    subject.append(2)
    subject.append(3)
    subject.append(5)
    subject.prepend(1)
    subject.prepend(0)
    subject.insert(4, before: subject.tail)

    current_node = subject.head

    6.times do |n|
      expect(current_node.value).to be(n)  
      current_node = current_node.next_node
    end

    current_node = subject.tail

    6.times do |n|
      expect(current_node.value).to be(5 - n)  
      current_node = current_node.prev_node
    end
  end

  it "deletes items by unlinking them" do
    subject.append("A")
    subject.append("B")
    subject.append("C")

    node = subject.find("B")
    subject.delete(node)

    expect(subject.find("B")).to be_nil
    expect(subject.head.next_node). to eq subject.tail
    expect(subject.tail.prev_node). to eq subject.head
  end

  describe "#each" do
    it "executes a block with each item as an argument" do
      subject.append("a")
      subject.append("b")
      subject.append("c")

      %w[a b c].each do |item|
        # Call some arbitrary method with each item to assert
        # that ResizingArray#each works
        expect(String).to receive(:try_convert).with(item)
      end

      subject.each do |item|
        String.try_convert(item)
      end
    end

    it "raises an error if no block is provided" do
      subject.append("a")

      expect { subject.each }.to raise_error(ArgumentError)
    end
  end


end
