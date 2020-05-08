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

  # Confused? Watch this!
  # https://www.cs.usfca.edu/~galles/visualization/AVLtree.html
  context "rotating nodes to keep subtree heights within 1 of each other" do
    it "rotates right-heavy subtrees to maintain balance" do
      node = tree.insert(8)
      expect(node.parent.value).to be 9
      expect(node.parent.right.value).to be 33
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
      # for a given node (33 in this case, because it is the nearest ancestor
      # of the new node for whom the invariant is violated) cannot differ by
      # more than 1.
      # So we rebalance the right subtree such that it looks like:
      #            5
      #          /   \
      #         1     7
      #        /     / \
      #      -3     7   9
      #                / \
      #               8   33

      node = tree.insert(16)
      expect(node.parent.value).to be 33
      expect(node.parent.parent.value).to be 9
      expect(node.parent.parent.left.value).to be 7
      expect(node.parent.parent.left.left.value).to be 7
      expect(node.parent.parent.left.right.value).to be 8
      # This time without rebalancing we'd end up with the right subtree of 7
      # differing from the left by more than 1. So we must rotate again:
      #             5
      #          /    \
      #         1       9
      #        /     /    \
      #      -3     7      33
      #           /  \    /
      #          7    8  16
      # The rotation algorithm goes like this:
      # traverse up parent-by-parent from the newly inserted node until you find
      # one for whom the invariant is violated. Once you do, you know that the
      # violation will be a difference in subtree height of exactly 1, because
      # any existing violation would've been corrected by a previous rotation.
      # If the node is right-heavy we need to "replace" it by its first child
      # on the right side as in the diagram above and vice versa for the left side
      values = []

      tree.each do |node|
        values << node.value
      end

      expect(values).to eq [-3, 1, 5, 7, 7, 8, 9, 16, 33]
    end

    it "rotates left-heavy subtrees to maintain balance"
    it "makes child nodes grandchildren when a rotation leads to a new child being added to a node"
    # Eg if 11 was just inserted;
    #             5
    #          /    \
    #         0       7
    #              /    \
    #             6      9
    #                      \
    #                       11
    # 11's grandparent 7 is actually not in violation of the invariant constraint.
    # But, as we traverse upwards, we find that the great-grandparent 5 is in violation.
    # So we need to rotate 7 up and make 5 the left child of 7. But 7 already
    # has a left child, 6. So, we make 6 the right child of 5.
    #                 7
    #              /    \
    #             5      9
    #            / \       \
    #           0   6       11
    it "rotates after deleting a node leaves the tree unbalanced"
    # Eg if we delete 0;
    #             5
    #          /    \
    #         0       7
    #              /    \
    #             6      9
    # We traverse upwards to 5 and see that it is in violation of the invariant constraint:
    #             5
    #               \
    #                 7
    #              /    \
    #             6      9
    # So we need to rotate 7 up and make 5 the left child of 7. But 7 already
    # has a left child, 6. So, we make 6 the right child of 5.
    #                 7
    #              /    \
    #             5      9
    #              \       \
    #               6       11
  end
end
