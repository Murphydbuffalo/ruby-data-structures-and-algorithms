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

    if value <= parent.value
      parent.left = new_node
    else
      parent.right = new_node
    end

    adjust_balances(parent, new_node, operation: :insert)

    new_node
  end

  def delete(node)
    return if node.nil?

    parent = node.parent
    was_left_child = parent.left == node unless parent.nil?

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

    adjust_balances(parent, node, operation: :delete, was_left_child: was_left_child)

    true
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

    def in_order_successor(node = right)
      return node if node.left.nil?
      in_order_successor(node.left)
    end

    def in_order_predecessor(node = left)
      return node if node.right.nil?
      in_order_predecessor(node.right)
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

  def depth_from(node)
    nodes = [node].compact
    depth = 0

    until nodes.empty?
      depth += 1
      nodes = nodes.map { |n| [n.left, n.right] }.flatten.compact
    end

    depth
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
        node.balance = child.balance = 0
      elsif same_direction_grandchild.nil? && opposite_direction_grandchild
        # Pre-rotation
        # (1)
        #    \
        #     (3)
        #    /
        # (2)
        # Post-rotation
        #      (2)
        #    /    \
        # (1)      (3)
        swap_parents_of_node_and_child(node, opposite_direction_grandchild)
        opposite_direction_grandchild.right = child
        opposite_direction_grandchild.left = node
        child.parent = node.parent = opposite_direction_grandchild
        node.right = child.left = nil
        node.balance = child.balance = 0
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

        node.balance = depth_from(node.right) - depth_from(node.left)
        child.balance = depth_from(child.right) - depth_from(child.left)
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
        node.balance = child.balance = 0
      elsif same_direction_grandchild.nil? && opposite_direction_grandchild
        # Pre-rotation
        #         (3)
        #        /
        #     (1)
        #        \
        #         (2)
        # Post-rotation
        #      (2)
        #    /    \
        # (1)      (3)
        swap_parents_of_node_and_child(node, opposite_direction_grandchild)
        opposite_direction_grandchild.left = child
        opposite_direction_grandchild.right = node
        child.parent = node.parent = opposite_direction_grandchild
        child.right = node.left = nil
        node.balance = child.balance = 0
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

        node.balance = depth_from(node.right) - depth_from(node.left)
        child.balance = depth_from(child.right) - depth_from(child.left)
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

  def adjust_balances(parent, node, operation:, was_left_child: false)
    raise ArgumentError, "operation must be :insert or :delete" unless %i[insert delete].include?(operation)
    return if parent.nil?

    adjust_left = was_left_child || parent.left == node

    balance_adjustment = adjust_left ? -1 : 1
    balance_adjustment *= -1 if operation == :delete
    parent.balance += balance_adjustment

    return rotate(parent) if parent.violating_balance_invariant?
    return if parent.balanced? && operation == :insert

    adjust_balances(parent.parent, parent, operation: operation)
  end
end
