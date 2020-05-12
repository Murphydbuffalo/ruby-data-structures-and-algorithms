require "rspec"
require "./avl_tree"

describe AVLTree do
  subject(:tree) do
    t = described_class.new

    t.insert(5)
    expect(t.root.balance).to be 0

    t.insert(7)
    expect(t.root.balance).to be 1

    t.insert(1)
    expect(t.root.balance).to be 0

    t.insert(-3)
    expect(t.root.balance).to be -1

    t.insert(33)
    expect(t.root.balance).to be 0

    t.insert(7)
    expect(t.root.balance).to be 0

    t.insert(9)
    expect(t.root.balance).to be 1
    #            5
    #          /   \
    #         1     7
    #        /     / \
    #      -3     7   33
    #                /
    #               9
    t
  end

  it "inserts nodes in sorted order by updating references to/from other nodes" do
    expect(tree.root.value).to be 5

    # Left subtree
    expect(tree.root.left.value).to be 1

    # Left -> Left
    expect(tree.root.left.left.value).to be -3
    # Left -> Left -> Left
    expect(tree.root.left.left.left).to be nil
    # Left -> Left -> Right
    expect(tree.root.left.left.right).to be nil

    # Left -> Right
    expect(tree.root.left.right).to be nil

    # Right subtree
    expect(tree.root.right.value).to be 7

    # Right -> Left
    expect(tree.root.right.left.value).to be 7
    # Right -> Left -> Left
    expect(tree.root.right.left.left).to be nil
    # Right -> Left -> Right
    expect(tree.root.right.left.right).to be nil

    # Right -> Right
    expect(tree.root.right.right.value).to be 33
    # Right -> Right -> Left
    expect(tree.root.right.right.left.value).to be 9
    # Right -> Right -> Left -> Right
    expect(tree.root.right.right.left.right).to be nil
    # Right -> Right -> Left -> Left
    expect(tree.root.right.right.left.left).to be nil

    # Right -> Right -> Right
    expect(tree.root.right.right.right).to be nil
  end

  it "iterates over nodes in order" do
    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 5, 7, 7, 9, 33]
  end

  it "finds nodes by value" do
    node = tree.find(7)
    expect(node.value).to be 7
    expect(node.left.value).to be 7
    expect(node.right.value).to be 33
  end

  it "deletes a node with no children" do
    expect(tree).not_to receive(:rotate)
    # Right side
    node = tree.find(9)
    expect(tree.delete(node)).to be true

    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 5, 7, 7, 33]
    expect(tree.root.right.right.value).to be 33

    # Left side
    node = tree.find(-3)
    tree.delete(node)

    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [1, 5, 7, 7, 33]
  end

  it "deletes a node with one child" do
    expect(tree).not_to receive(:rotate)

    # Right side
    node = tree.find(33)
    expect(tree.delete(node)).to be true

    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 5, 7, 7, 9]

    # Left side
    node = tree.find(1)
    expect(tree.delete(node)).to be true

    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 5, 7, 7, 9]
  end

  it "deletes a node with two children" do
    expect(tree).not_to receive(:rotate)

    node = tree.find(7)
    expect(tree.delete(node)).to be true

    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 5, 7, 9, 33]

    expect(tree.root.value).to be 5

    # Left subtree
    expect(tree.root.left.value).to be 1
    # Left -> Left
    expect(tree.root.left.left.value).to be -3
    # Left -> Left -> Left
    expect(tree.root.left.left.left).to be nil
    # Left -> Left -> Right
    expect(tree.root.left.left.right).to be nil

    # Left -> Right
    expect(tree.root.left.right).to be nil

    # Right subtree
    expect(tree.root.right.value).to be 9

    # Right -> Left
    expect(tree.root.right.left.value).to be 7
    # Right -> Left -> Left
    expect(tree.root.right.left.left).to be nil
    # Right -> Left -> Right
    expect(tree.root.right.left.right).to be nil

    # Right -> Right
    expect(tree.root.right.right.value).to be 33
    # Right -> Right -> Left
    expect(tree.root.right.right.left).to be nil
    # Right -> Right -> Right
    expect(tree.root.right.right.right).to be nil
  end

  it "deletes the root" do
    expect(tree.delete(tree.root)).to be true

    values = []

    tree.each do |node|
      values << node.value
    end

    expect(values).to eq [-3, 1, 7, 7, 9, 33]
    root = tree.root
    expect(root.value).to be 7
    expect(root.left.value).to be 1
    expect(root.right.value).to be 9
  end

  context "rotating nodes to keep subtree heights within 1 of each other" do
    it "rotates left-heavy subtrees with only a left grandchild" do
      node = tree.insert(8)
      expect(node.parent.value).to be 9
      expect(node.parent.right.value).to be 33

      root = tree.root
      left = root.left
      right = root.right
      expect(root.balance).to be 1
      expect(left.balance).to be -1
      expect(right.balance).to be 1

      tree.each do |node|
        expect(node.balance).to be 0 unless [root, left, right].include?(node)
      end

      # Without rebalancing we'd end up with a parent of 9 for the new node:
      #            5
      #          /   \
      #         1     7
      #        /     / \
      #      -3     7   33
      #                /
      #               9
      #             /
      #            8
      # Which violates our specified invariant that the height of the subtrees
      # for a given node (33 in this case) cannot differ by more than 1.
      # So we rebalance the right subtree such that it looks like:
      #            5
      #          /   \
      #         1     7
      #        /     / \
      #      -3     7   9
      #                / \
      #               8   33
    end

    it "rotates left-heavy subtrees with only a right grandchild" do
      tree = described_class.new
      tree.insert(5)
      tree.insert(3)
      tree.insert(4)
      # Without rotation we'd end up with the following tree, which leaves the
      # root, 5, with a balance of -2.
      #      5
      #     /
      #    3
      #     \
      #      4
      # So we rotate to:
      #      4
      #     / \
      #    3   5

      expect(tree.root.value).to be 4
      expect(tree.root.right.value).to be 5
      expect(tree.root.left.value).to be 3

      tree.each do |node|
        expect(node.balance).to be 0
      end
    end

    it "rotates left-heavy subtrees with both right and left grandchildren" do
      tree = described_class.new
      tree.insert(5)
      tree.insert(3)
      node = tree.insert(6)
      tree.insert(4)
      tree.insert(2)
      tree.delete(node)
      # Without rotation we'd end up with the following tree, which leaves the
      # root, 5, with a balance of -2
      #      5
      #     /
      #    3
      #   / \
      #  2   4
      # So we rotate to:
      #      3
      #    /   \
      #   2    5
      #       /
      #      4
      expect(tree.root.value).to be 3
      expect(tree.root.right.value).to be 5
      expect(tree.root.right.left.value).to be 4
      expect(tree.root.left.value).to be 2

      values = []

      tree.each do |node|
        values << node.value
      end

      expect(values).to eq [2, 3, 4, 5]
      expect(tree.root.balance).to be 1
      expect(tree.root.left.balance).to be 0
      expect(tree.root.right.balance).to be -1
      expect(tree.root.right.left.balance).to be 0
    end

    it "rotates right-heavy subtrees with only a right grandchild" do
      tree = described_class.new
      tree.insert(1)
      tree.insert(2)
      tree.insert(3)
      # Without rotation we'd end up with the following tree, which leaves the
      # root, 5, with a balance of -2
      #      1
      #       \
      #        2
      #         \
      #          3
      # So we rotate to:
      #      2
      #     / \
      #    1   3
      expect(tree.root.value).to be 2
      expect(tree.root.right.value).to be 3
      expect(tree.root.left.value).to be 1

      tree.each do |node|
        expect(node.balance).to be 0
      end
    end

    it "rotates right-heavy subtrees with only a right grandchild" do
      tree = described_class.new
      tree.insert(1)
      tree.insert(2)
      tree.insert(3)
      # Without rotation we'd end up with the following tree, which leaves the
      # root, 5, with a balance of -2
      #      1
      #       \
      #        3
      #      /
      #    2
      # So we rotate to:
      #      2
      #     / \
      #    1   3
      expect(tree.root.value).to be 2
      expect(tree.root.right.value).to be 3
      expect(tree.root.left.value).to be 1

      tree.each do |node|
        expect(node.balance).to be 0
      end
    end

    it "rotates right-heavy subtrees with both left and right grandchildren" do
      tree.insert(8)
      node = tree.insert(16)
      # This time without rebalancing we'd end up with the right subtree of 7
      # differing from the left by more than 1
      #            5
      #          /   \
      #         1     7
      #        /     / \
      #      -3     7   9
      #                / \
      #               8   33
      #                   /
      #                  16
      # So we must rotate again:
      #             5
      #          /    \
      #         1      9
      #        /     /   \
      #      -3     7     33
      #           /  \    /
      #          7    8  16
      expect(node.parent.value).to be 33
      expect(node.parent.parent.value).to be 9
      expect(node.parent.parent.left.value).to be 7
      expect(node.parent.parent.left.left.value).to be 7
      expect(node.parent.parent.left.right.value).to be 8
      values = []

      tree.each do |node|
        values << node.value
      end

      expect(values).to eq [-3, 1, 5, 7, 7, 8, 9, 16, 33]
      expect(tree.root.balance).to be 1
      expect(tree.root.left.balance).to be -1
      expect(tree.root.left.left.balance).to be 0
      expect(tree.root.right.balance).to be 0
      expect(tree.root.right.right.balance).to be -1
      expect(tree.root.right.left.balance).to be 0
      expect(tree.root.right.left.left.balance).to be 0
      expect(tree.root.right.left.right.balance).to be 0
    end
  end
end
