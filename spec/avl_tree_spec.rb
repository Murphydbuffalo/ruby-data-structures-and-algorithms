require "rspec"
require "./avl_tree"
require "pry"

describe AVLTree do
  subject(:integer_tree) do
    tree = described_class.new 
    tree.insert(5)
    tree.insert(7)
    tree.insert(1)
    tree.insert(-3)
    tree.insert(33)
    tree.insert(7)
    tree.insert(9)

    #            5
    #          /   \
    #         1     7 
    #        /     / \
    #      -3     7   33
    #                / 
    #               9 
    #                   
    tree
  end

  it "inserts nodes in sorted order by updating references to/from other nodes" do
    expect(integer_tree.root.value).to be 5

    # Left subtree
    expect(integer_tree.root.left.value).to be 1
      # Left -> Left
      expect(integer_tree.root.left.left.value).to be -3
        # Left -> Left -> Left
        expect(integer_tree.root.left.left.left).to be nil
        # Left -> Left -> Right
        expect(integer_tree.root.left.left.right).to be nil

      # Left -> Right
      expect(integer_tree.root.left.right).to be nil

    # Right subtree
    expect(integer_tree.root.right.value).to be 7

      # Right -> Left
      expect(integer_tree.root.right.left.value).to be 7
        # Right -> Left -> Left
        expect(integer_tree.root.right.left.left).to be nil
        # Right -> Left -> Right
        expect(integer_tree.root.right.left.right).to be nil

      # Right -> Right
      expect(integer_tree.root.right.right.value).to be 33
        # Right -> Right -> Left
        expect(integer_tree.root.right.right.left.value).to be 9
          # Right -> Right -> Left -> Right
          expect(integer_tree.root.right.right.left.right).to be nil
          # Right -> Right -> Left -> Left
          expect(integer_tree.root.right.right.left.left).to be nil

        # Right -> Right -> Right
        expect(integer_tree.root.right.right.right).to be nil
  end

  it "iterates over nodes in order" do
    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 5, 7, 7, 9, 33]
  end

  it "finds nodes by value" do
    node = integer_tree.find(7)
    expect(node.value).to be 7
    expect(node.left.value).to be 7
    expect(node.right.value).to be 33
  end

  it "deletes a node with no children" do
    # Left side
    node = integer_tree.find(-3)
    expect(integer_tree.delete(node)).to be true

    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [1, 5, 7, 7, 9, 33]

    # Right side
    node = integer_tree.find(9)
    expect(integer_tree.delete(node)).to be true

    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [1, 5, 7, 7, 33]
    expect(integer_tree.root.right.right.value).to be 33
  end


  it "deletes a node with one child" do
    # Left side
    node = integer_tree.find(1)
    expect(integer_tree.delete(node)).to be true

    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 5, 7, 7, 9, 33]

    # Right side
    node = integer_tree.find(33)
    expect(integer_tree.delete(node)).to be true

    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 5, 7, 7, 9]
    expect(integer_tree.root.right.right.value).to be 9
  end

  it "deletes a node with two children" do
    node = integer_tree.find(7)
    expect(integer_tree.delete(node)).to be true

    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 5, 7, 9, 33]

    expect(integer_tree.root.value).to be 5

    # Left subtree
    expect(integer_tree.root.left.value).to be 1
      # Left -> Left
      expect(integer_tree.root.left.left.value).to be -3
        # Left -> Left -> Left
        expect(integer_tree.root.left.left.left).to be nil
        # Left -> Left -> Right
        expect(integer_tree.root.left.left.right).to be nil

      # Left -> Right
      expect(integer_tree.root.left.right).to be nil

    # Right subtree
    expect(integer_tree.root.right.value).to be 9

      # Right -> Left
      expect(integer_tree.root.right.left.value).to be 7
        # Right -> Left -> Left
        expect(integer_tree.root.right.left.left).to be nil
        # Right -> Left -> Right
        expect(integer_tree.root.right.left.right).to be nil

      # Right -> Right
      expect(integer_tree.root.right.right.value).to be 33
        # Right -> Right -> Left
        expect(integer_tree.root.right.right.left).to be nil
        # Right -> Right -> Right
        expect(integer_tree.root.right.right.right).to be nil
  end

  it "deletes the root" do
    expect(integer_tree.delete(integer_tree.root)).to be true

    values = []

    integer_tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 7, 7, 9, 33]
    root = integer_tree.root
    expect(root.value).to be 7
    expect(root.left.value).to be 1
    expect(root.right.value).to be 7
  end

  it "rotates subtrees to maintain balance"
end
