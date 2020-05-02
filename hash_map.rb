require "./linked_list"
require "./resizing_array"
require "./hash_code"

# Hashmaps (AKA hashtables or just "hashes" in Ruby) can read, write, and
# delete entries in O(1) (constant time) in the average case. However, in
# the worst case these operations occur in O(n) (linear time) because of the
# need for rehashing. What rehashing is an why it's necessary becomes apparent
# once you understand how hashmaps work under the hood.
#
# In this implementation we will create a hashmap by using the linked list and
# dynamically resizing array data structures we've already built, along with a
# crucial third piece: a hash function.
#
# Hash functions take in some arbitrary data and output an integer value known
# as a "hash", "hash digest", or "hash code" that has several useful properties:
# 1. It is always of the same number of digits
# 2. Its input value cannot be deduced from its output value.
# 3. It is uniformly random, meaning if the possible range of values for you
#    hash function is 1-100, each of those numbers is equally likely to be
#    produced. You won't get way more 50s than you will 2s.
# 4. It is always the same for a given input, meaning the hash function is
#    deterministic.
# 5. There are few "collisions", which is when different inputs produce the
#    same output.
#
# Hash functions - if they are good - are also very fast. This is essential for
# the efficacy of the hashmap. This speed, along with points 3-5 above make the
# hashmap data structure possible.
#
# We have written a very terrible hash function (`HashCode.for(value)`) for use
# in this hashmap class. It takes the underlying bytes of the string
# representation of whatever you give it, squares them, and trucates the
# results. 
#
# OK, so how does it work? Hashmaps take advantage of the fact that reading,
# writing, or deleting the element at a given index in an array can happen
# in constant time. Read the comments in the `ResizingArray` class for more
# information on why that is.
#
# The obvious limitation to this feature of arrays is that in order to take
# advantage of those constant time operations you must know the index of the
# element you'd like to access.
#
# So, hashmaps use hash functions to provide a way of deducing the desired
# array index given a "key" that identifies the value at that index.
#
# Hashmaps take the key and run it through their hash function, producing a
# uniformly random integer hash digest for that key. They then use the modulus
# operator `%` to produce an integer that is within the size of the array.
# Eg, given a hash digest of 1001 and an array of size 10, `1001 % 10` gives
# you `1`. We use this number as the array index for the key and its associated
# value.
#
# Because a hash function always outputs the same digest given the same input
# we can look up this array index in the same way when it's time to read
# a value from the hashmap by its key. 
#
# But what about the hash collisions mentioned above? It is possible to produce
# the same digest for multiple given inputs. To resolve such collisions We turn
# to the linked list. At each index in the array, rather than directoy storing
# the value we want to write to the hashmap, we store a linked list. Each node
# in the linked list contains both the key and the value. If there is
# a collision while writing to the hashmap, we simply append another node to the list.
# When reading a value from the hashmap we iterate through the linked list at
# the appropriate array index until we find the key we are interested in.
#
# You may be asking yourself: "if we have to iterate through a list, how do
# hashmaps have constant time lookups?". The answer is that we ensure there is
# never a linked list with a large number of nodes to be iterated through.
#
# This is where rehashing comes in. As we insert key-value pairs into the
# hashmap we increment a count. If the ratio of the number of key-value pairs
# (entries) relative to the capacity of the array rises above a certain level
# we will creat a new, much larger, array and copy all of the existing values
# to it. Given a good hash function, this makes sure that we never have to do
# much iteration to find the key-value pair we are interested in.
#
# Rehashing involves recalculating the hash and array index for every key,
# because the size of the array is now different, and so the denominator in our
# `hash_digest % array_size` function is also different.
#
# Congratulations! Now you too can implement your own very, very terrible
# hashmap!
#
# Now that we understand how they work, we are in a position to understand some
# of the drawbacks to hashmaps. Their guarantee of constant time operations in
# the average case is very groovy indeed. But we know that because of the need
# for rehashing every once and a while an insert operation will take linear
# time. So if you have a performance-critical application and need to store
# many thousands or millions of entries in memory, a hashmap may *not* be the
# best choice.
#
# Further, hashmaps don't keep an kind of order to their entries. So you'll need
# to do your own sorting if that's important to your application.
#
# Finally, hashes also have poor locality of refernence because, like linked
# lists they don't store values sequentially in memory.
#
# Self-balancing binary search trees perform reads, writes, and deletes in 
# O(log n) in the average case *and* in the worst case. So if avoiding slow
# operations in imperative you may want a tree, despite its slower average
# operation time.
#
# Further, trees order nodes as they are inserted, so you easily can traverse
# the entire tree in sorted order in log n time. 
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
