# The idea with this class is to show in Ruby how you might implement a 
# dynamically resizing array, without leveraging the `Array` class from
# the standard library.
#
# We use the methods `instance_variable_get`, `instance_variable_set`
# and `remove_instance_variable` to simulate allocating, deallocating,
# and reading/writing to addresses in memory, as you would do in a 
# language like C if you wanted to implement this data structure.
#
# The array is initialized with some amount of `capacity` used to
# store its values, and that capacity is expanded as needed when
# values are added to the array. Capacity is reduced if there is
# a lot of unused space after an item is removed from the array.
#
# The logic here is pretty unsophisticated: for example you could 
# imagine adding an additional check to not decrease array capacity
# below a certain absolute level to avoid frequently resizing small
# arrays.
#
# As noted in `linked_list.rb` arrays store their values in a contiguous block
# of memory. This means that you can access arbitrary points in the array in
# constant time by simply supplying an `index`, which under the hood is used as
# an offset from the beginning of the array's address space. Concretely this
# means that if the VM or compiler knows both how much memory is used for each
# element in the array and what the address of the first value is, it can
# produce instructions to find any element via index by simply moving
# `index * num_bytes_per_element` from the start of the array.
#
# A downside to this sequential storage approach is that adding or removing
# elements anywhere besides the tail (end) of the array means that all of
# the existing elements from the point of the operation on must be copied to
# new addresses in order to keep the data in sequence. Eg, if you have 10
# elements in an array and delete the 5th one, elements 6-10 must be copied
# into positions 5-9. Similarly, if you have 10 elements and insert a new one
# at position 5 (zero-based index 4) you must move elements 5-10 to positions
# 6-11 (and you must resize the array if its current capacity is only 10).
class ResizingArray
  CAPACITY_CHANGE_FACTOR      = 0.50
  DECREASE_CAPACITY_THRESHOLD = 0.33

  def initialize(*values)
    index = 0

    while index < values.size
      instance_variable_set("@item_#{index}", values[index])
      index += 1
    end

    @size     = index
    @capacity = [@size, 10].max
  end

  attr_reader :size

  def capacity
    @capacity.to_i
  end

  # O(1) (constant time), just move `index * num_byte_per_element` from the
  # start of the array.
  def [](index)
    validate_index!(index)
    instance_variable_get("@item_#{index}")
  end

  def []=(index, value)
    validate_index!(index)
    instance_variable_set("@item_#{index}", value)
  end

  def first
    self.[](0)
  end

  def last
    self.[](size - 1)
  end

  # O(1) unless the capacity of the array must be increased. No moving of
  # existing values required.
  def push(value)
    instance_variable_set("@item_#{size}", value)
    @size += 1
    increase_capacity_if_needed
    value
  end

  def enqueue(value)
    push(value)
  end

  def pop
    return if size.zero?
    @size -= 1

    instance_variable_get("@item_#{size}").tap do
      decrease_capacity_if_needed
      remove_instance_variable("@item_#{size}")
    end
  end

  # O(n) in the worst case because we must copy existing values over to
  # new positions in the array..
  def insert_at(index, value)
    validate_index!(index)
    increment_all_indexes_starting_at(index)
    instance_variable_set("@item_#{index}", value)
    @size += 1
    increase_capacity_if_needed
    value
  end

  def delete_at(index)
    validate_index!(index)
    return if size.zero?
    @size -= 1

    instance_variable_get("@item_#{index}").tap do
      remove_instance_variable("@item_#{index}")
      decrement_all_indexes_starting_at(index + 1)
      decrease_capacity_if_needed
    end
  end

  def unshift(value)
    insert_at(0, value)
  end

  def shift
    delete_at(0)
  end

  def dequeue
    shift
  end

  def each
    raise ArgumentError, "no block given" unless block_given?

    index = 0

    while index < size
      yield instance_variable_get("@item_#{index}")
      index += 1
    end

    nil
  end

  def map(&block)
    raise ArgumentError, "no block given" unless block_given?

    new_array = self.class.new
    each do |item|
      new_array.push(block.call(item))
    end

    new_array
  end

  def select(&block)
    raise ArgumentError, "no block given" unless block_given?

    new_array = self.class.new
    each do |item|
      new_array.push(item) if block.call(item)
    end

    new_array
  end
 
  private

  def increase_capacity_if_needed
    @capacity *= (1 + CAPACITY_CHANGE_FACTOR) if size == capacity
  end

  def decrease_capacity_if_needed
    @capacity *= CAPACITY_CHANGE_FACTOR if size < (DECREASE_CAPACITY_THRESHOLD * capacity)
  end

  def increment_all_indexes_starting_at(index)
    i = size - 1

    while i >= index
      old_reference = instance_variable_get("@item_#{i}")
      instance_variable_set("@item_#{i + 1}", old_reference)
      i -= 1
    end
  end

  def decrement_all_indexes_starting_at(index)
    while index <= size
      old_reference = instance_variable_get("@item_#{index}")
      instance_variable_set("@item_#{index - 1}", old_reference)
      index += 1
    end
  end

  def validate_index!(index)
    return if index >= 0 && index <= size
    raise ArgumentError,
      "index cannot be negative or greater than the current size of the array"
  end
end
