class AVLTree
  attr_accessor :root

  def each(&block)
    traverse_left_to_right(root, &block)
  end

  def find(value)
    binary_search(root, value) do |node|
      return node if node.value == value
    end
  end

  def insert(value)
    new_node = Node.new(value)
    return self.root = new_node if root.nil?

    parent = nil

    binary_search(root, value) do |node|
      parent = node unless node.nil?
    end

    new_node.parent = parent
    child           = new_node

    if value <= parent.value
      parent.left = new_node
    else
      parent.right = new_node
    end

    until parent.nil? do
      balance_adjustment = child == parent.left ? -1 : 1
      parent.balance += balance_adjustment

      if parent.violating_balance_invariant?
        rotate(parent)
        break
      end

      break if parent.balanced?

      child = parent
      parent = parent.parent
    end

    new_node
  end

  def delete(node)
    return if node.nil?

    parent = node.parent
    is_left_child = parent.left == node unless parent.nil?

    if node.children.none?
      if node.root?
        self.root = nil
      elsif node == parent.right
        parent.right = nil
      else
        parent.left = nil
      end
    elsif node.children.one?
      child = node.children.first

      if node.root?
        self.root = child
      elsif node == parent.right
        parent.right = child
      else
        parent.left = child
      end

      child.parent = parent
    else
      if node.root? || node == parent.right
        node.value = node.in_order_successor.value
        return delete(node.in_order_successor)
      else
        node.value = node.in_order_predecessor.value
        return delete(node.in_order_predecessor)
      end
    end

    # TODO: DRY this out with the logic in `insert`. Just need an argument to
    # flip the sign of the balance adjustment.
    until parent.nil? do
      (is_left_child = parent.left == node) if is_left_child.nil?

      balance_adjustment = is_left_child ? 1 : -1
      parent.balance += balance_adjustment

      if parent.violating_balance_invariant?
        rotate(parent)
        break
      end

      is_left_child = nil
      node = parent
      parent = parent.parent
    end

    true
  end

  def print
    # TODO: figure out the depth or approximate depth of the tree
    # Maybe call #each, add all nodes to an array
    # indent root node based on how deep tree is
    # indent subsequent layers relative to the root
  end

  private

  class Node
    def initialize(value)
      @value   = value
      @balance = 0
    end

    attr_accessor :value, :parent, :left, :right, :balance

    def children
      [left, right].compact
    end

    # TODO: take notes. Why is it the case that right.left always produces the
    # in-order successor? And why does left.right always produce the in-order
    # predecessor?
    # Why does swapping their value with the node to be deleted's make sense?
    # Finally, why is recursion nice for cleaning up the IOS/IOP after doing
    # this?
    def in_order_successor
      right.left
    end

    def in_order_predecessor
      left.right
    end

    def root?
      parent.nil?
    end

    def balanced?
      balance.zero?
    end

    def imbalanced?
      !balanced?
    end

    def violating_balance_invariant?
      (balance < -1) || (balance > 1)
    end

    def right_heavy?
      balance > 1
    end

    def left_heavy?
      balance < 1
    end
  end

  def traverse_left_to_right(node, &block)
    raise ArgumentError, "no block given" unless block_given?
    return if node.nil?

    traverse_left_to_right(node.left, &block)
    yield node
    traverse_left_to_right(node.right, &block)
  end

  def binary_search(node, value, &block)
    return ArgumentError, "no block given" unless block_given?
    return if node.nil?

    yield node

    if value <= node.value
      node = node.left
    else
      node = node.right
    end

    binary_search(node, value, &block)
  end

  def rotate(node)
    if node.right_heavy?
      child = node.right
      opposite_direction_grandchild = child.left
      same_direction_grandchild = child.right

      if same_direction_grandchild && opposite_direction_grandchild.nil?
        # Pre-rotation
        # (1)
        #    \
        #     (2)
        #        \
        #         (3)

        # Post-rotation
        #      (2)
        #    /    \
        # (1)      (3)
        swap_parents_of_node_and_child(node, child)
        child.left = node
        node.parent = child
        node.right = nil

        node.balance = 0
        child.balance = 0
      elsif same_direction_grandchild.nil? && opposite_direction_grandchild
        # Pre-rotation
        # (1)
        #    \
        #     (3)
        #    /
        # (2)

        # Intermediate step to make it so a second rotation can balance the tree
        # (1)
        #   \
        #    (2)
        #      \
        #      (3)
        # TODO: can we eliminate some of these steps?
        swap_parents_of_node_and_child(child, opposite_direction_grandchild)
        opposite_direction_grandchild.right = child
        child.parent = opposite_direction_grandchild
        child.left = nil
        node.right = opposite_direction_grandchild

        # Post-rotation
        #      (2)
        #    /    \
        # (1)      (3)
        swap_parents_of_node_and_child(node, opposite_direction_grandchild)
        opposite_direction_grandchild.left = node
        node.parent = opposite_direction_grandchild
        node.right = nil

        node.balance = 0
        child.balance = 0
      elsif same_direction_grandchild && opposite_direction_grandchild
        # Pre-rotation
        # (1)
        #    \
        #     (3)
        #    /   \
        #  (2)    (5)

        # Post-rotation
        #      (3)
        #    /    \
        # (1)      (5)
        #    \
        #     (2)
        swap_parents_of_node_and_child(node, child)
        child.left = node
        node.parent = child
        node.right = opposite_direction_grandchild
        opposite_direction_grandchild.parent = node

        node.balance = 1
        child.balance = -1
      end
    elsif node.left_heavy?
      child = node.left
      opposite_direction_grandchild = child.right
      same_direction_grandchild = child.left

      if same_direction_grandchild && opposite_direction_grandchild.nil?
        # Pre-rotation
        #         (3)
        #        /
        #     (2)
        #    /
        # (1)

        # Post-rotation
        #      (2)
        #    /    \
        # (1)      (3)
        swap_parents_of_node_and_child(node, child)
        child.right = node
        node.parent = child
        node.left = nil

        node.balance = 0
        child.balance = 0
      elsif same_direction_grandchild.nil? && opposite_direction_grandchild
        # Pre-rotation
        #         (3)
        #        /
        #     (1)
        #        \
        #         (2)

        # Intermediate step to make it so a second rotation can balance the tree
        #         (3)
        #        /
        #     (2)
        #    /
        # (1)
        swap_parents_of_node_and_child(child, opposite_direction_grandchild)
        opposite_direction_grandchild.left = child
        child.right = nil
        child.parent = opposite_direction_grandchild
        node.left = opposite_direction_grandchild

        # Post-rotation
        #      (2)
        #    /    \
        # (1)      (3)
        swap_parents_of_node_and_child(node, opposite_direction_grandchild)
        opposite_direction_grandchild.right = node
        node.parent = opposite_direction_grandchild
        node.left = nil

        node.balance = 0
        child.balance = 0
      elsif same_direction_grandchild && opposite_direction_grandchild
        # Pre-rotation
        #            (5)
        #          /
        #       (3)
        #     /   \
        #  (2)    (4)

        # Post-rotation
        #      (3)
        #    /    \
        # (2)      (5)
        #         /
        #     (4)
        swap_parents_of_node_and_child(node, child)
        child.right = node
        node.parent = child
        node.left = opposite_direction_grandchild
        opposite_direction_grandchild.parent = node

        node.balance = -1
        child.balance = 1
      end
    end
  end

  def swap_parents_of_node_and_child(node, child)
    parent = node.parent

    if parent.nil?
      self.root = child
    elsif node == parent.right
      parent.right = child
    elsif node == parent.left
      parent.left = child
    end

    child.parent = parent
  end
end