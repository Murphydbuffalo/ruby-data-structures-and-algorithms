# Unlike an array, which always stores its values sequentially in
# a contiguous block of memory addresses linked lists do not need
# to keep their values adjacent to one another. Instead they rely
# on pointers from one node to the next/previous.
#
# This means that they have worse locality of reference than arrays,
# and therefore the underlying hardware is less able to cache
# some contiguous block of memory with all the nodes in the list.
#
# One tradeoff there is that in a memory-constrainted domain (the
# data you want to keep in memory is very large relative to the
# hardware) there must be a non-fragmented (contiguous) block of
# memory large enough to accomodate all the values of an array,
# whereas a linked list does not require those addresses to be
# contiguous/adjacent to one another.
class LinkedList
  attr_reader :head, :tail

  # O(n). In worst case we need to traverse the entire list from
  # head to tail or vice versa. No way to access items by index.
  def find(value = nil)
    current = head

    until current.nil? || (block_given? ? yield(current.value) : current.value == value)
      current = current.next_node
    end

    current
  end

  # O(1). Constant time given you have a reference to the node
  # you want to insert before/after. Just need to adjust the
  # references to next and previous nodes.
  def insert(value, after: nil, before: nil)
    new_node = Node.new(value)

    if after
      new_node.prev_node = after
      new_node.next_node = after.next_node

      after.next_node.prev_node = new_node if after.next_node
      after.next_node           = new_node
    elsif before
      new_node.prev_node       = before.prev_node
      before.prev_node.next_node = new_node if before.prev_node

      new_node.next_node = before
      before.prev_node   = new_node
    end

    @head = new_node if new_node.prev_node.nil?
    @tail = new_node if new_node.next_node.nil?

    new_node
  end

  def prepend(value)
    insert(value, before: head)
  end

  def append(value)
    insert(value, after: tail)
  end

  # O(1). Constant time given you have a reference to the node
  # you want to insert before/after. Just need to adjust the
  # references to next and previous nodes.
  def delete(node)
    return if node.nil?

    old_prev = node.prev_node
    old_next = node.next_node

    @head = old_next if node == head
    @tail = old_prev if node == tail

    old_prev.next_node = old_next if old_prev
    old_next.prev_node = old_prev if old_next

    node.next_node = nil
    node.prev_node = nil

    node
  end

  class Node
    def initialize(value, next_node: nil, prev_node: nil)
      @value     = value
      @next_node = next_node
      @prev_node = prev_node
    end

    attr_accessor :value, :next_node, :prev_node
  end
end

