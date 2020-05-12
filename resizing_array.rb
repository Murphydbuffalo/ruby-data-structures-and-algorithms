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
