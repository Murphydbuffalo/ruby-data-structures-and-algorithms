module LinkedList
  class Collection
    def initialize; end

    attr_reader :head, :tail

    def find(value)
      current = head

      until current.nil? || current.value == value
        current = current.next_node
      end

      current
    end

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

