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

    previous_node = nil

    binary_search(root, value) do |node|
      previous_node = node unless node.nil?
    end

    new_node.parent = previous_node

    if value <= previous_node.value
      previous_node.left = new_node
    else
      previous_node.right = new_node
    end

    new_node
  end

  def delete(node)
    return if node.nil?

    parent = node.parent

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
    else
      if node.root? || node == parent.right
        node.value = node.in_order_successor.value
        delete(node.in_order_successor)
      else
        node.value = node.in_order_predecessor.value
        delete(node.in_order_predecessor)
      end
    end

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
      [left, right]
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
end
