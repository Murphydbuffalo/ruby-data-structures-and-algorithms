require "./linked_list"
require "./resizing_array"
require "./hash_code"

class HashMap
  # https://en.wikipedia.org/wiki/Hash_table#Key_statistics
  LOAD_FACTOR = 0.75

  def initialize(key_value_pairs = [])
    num_buckets = [10, (key_value_pairs.length * 2)].max
    lists       = num_buckets.times.map { LinkedList.new }

    @array       = ResizingArray.new(*lists)
    @num_entries = 0

    key_value_pairs.each do |(key, value)|
      self.[]=(key, value)
    end
  end

  def [](key)
    index = array_index(key)
    list  = array[index]

    return if list.nil?

    list_node = list.find { |(tuple)| tuple.first == key }
    list_node.value.last unless list_node.nil?
  end

  def []=(key, value)
    array[array_index(key)].append(ResizingArray.new(key, value))
    @num_entries += 1

    rehash_all if needs_rehashing?
    value
  end

  def keys
    # We use Ruby's built-in Array class here only for ease of testing in the
    # specs
    result = []

    array.each do |list|
      next if list.nil?

      list.each do |node|
        result.push(node.first)
      end
    end

    result
  end

  def values
    # We use Ruby's built-in Array class here only for ease of testing in the
    # specs
    result = []

    array.each do |list|
      list.each do |node|
        result.push(node.last)
      end
    end

    result
  end

  private

  attr_accessor :array
  attr_reader   :num_entries

  # Replace the underlying array, so that we have more "buckets"
  # (elements in the array) to spread values out amongst. This helps to
  # preserve the constant time lookup of the hashmap, making it less likely
  # we'll have to iterate through the linked lists to find a specific key.
  #
  # We instantiate a new hashmap to avoid having to duplicate all of the code
  # for inserting new entries.
  def rehash_all
    key_value_pairs = keys.map do |key|
      [key, self.[](key)]
    end

    new_hash = self.class.new(key_value_pairs)

    self.array = new_hash.send(:array)

    true
  end

  # Assuming our hash code function outputs values uniformly at random then
  # we'll rehash when there are roughly 0.75 entries per element in the array.
  def needs_rehashing?
    num_entries > (array.size * LOAD_FACTOR)
  end

  def hash(key)
    HashCode.for(key)
  end

  def array_index(key)
    hash(key) % array.capacity
  end
end
