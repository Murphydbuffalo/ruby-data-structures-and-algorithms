require './linked_list'
require './resizing_array'
require './hash_code'

class HashMap
  def initialize(key_value_pairs: [])
    lists = 10.times.map { LinkedList.new }
    @array = ResizingArray.new(*lists)
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

  attr_reader :array

  def rehash_all
  end

  def needs_rehashing?
    false
  end

  def hash(key)
    HashCode.for(key)
  end

  def array_index(key)
    hash(key) % array.capacity
  end
end
