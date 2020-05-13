# Data structures built with Ruby
![A silly GIF of Jon Mulaney and Nick Kroll saying "ohhhh hello"](https://blog.chron.com/tubular/files/2014/05/oh-hello.gif)

If you're like me and come from a non-Computer-Science background and have been curious about how data structures such as linked lists, hash maps, binary search trees and arrays work and what the trade-offs between them are, then this is the place for you.

We'll cover why you might want to use a given data structure and will give examples of places you've probably encountered them in your day-to-day as a programmer, perhaps without you even knowing it.

You'll also learn about the performance characteristics of each data structure, and how those characteristics can vary greatly from the average case to the worst case.

We'll see how you can use different data structures to implement things like stacks, queues, and deques.

But perhaps most importantly, these implementations are bare bones (_for the love of God don't try to use them in production apps!_) and are written in Ruby in the hopes of making them easy to understand and play around with. Make a PR for improving our hash function or allowing our arrays to efficiently add and remove items from the front!

Each data structure is described in detail below and comes with a set of tests that describe what's going on in plain English.

I hope you learn and enjoy! Any feedback positive or negative would be most welcome and can take the form of a GitHub issue, pull request, or email to hello@danmurphy.codes.

To test things outs, pull down the repo and run:
```ruby
bundle
bundle exec rspec spec
```

## Table of contents
+ [Dynamic (resizing) arrays](#dynamic-arrays)
+ [Linked lists](#linked-lists)
+ [Hash maps](#hash-maps)
+ [Self-balancing binary search trees](#binary-search-trees)

## Dynamic arrays
You can find the code for dynamically resizing arrays in `resizing_array.rb` and the corresponding spec file.

The `Array` class you're familiar with from Ruby's standard library is an
implementation of a _dynamic_ or _automatically resizing_ array. If you think
about how an array behaves [in a lower-level language like C](https://www.tutorialspoint.com/cprogramming/c_arrays.htm#declaring-arrays) this terminology will begin to make sense.

In C you need to specify the _size_ of the array you want. If that array fills
up there is no built-in mechanism to increase the its size.
You must manually allocate more memory to store the additional items and copy them
over into a new array.

If you are removing elements from the array you'll probably want to de-allocate
("free") some of that memory so that your program isn't needlessly hogging your
computer's resources.

The idea with our `ResizingArray` class is to show in Ruby how you might implement
a dynamically resizing array, without leveraging the `Array` class from the
standard library.

We use the methods `instance_variable_get`, `instance_variable_set`
and `remove_instance_variable` to simulate allocating, de-allocating,
and reading/writing to addresses in memory, as you would do in a
language like C if you wanted to implement this data structure.

The array is initialized with some amount of `capacity` used to
store its values, and that capacity is expanded as needed when
values are added to the array. Capacity is reduced if there is
a lot of unused space after an item is removed from the array.

The logic here is pretty unsophisticated: for example you could
imagine adding an additional check to not decrease array capacity
below a certain absolute level to avoid frequently resizing small
arrays.

Arrays store their values in a contiguous block of memory.
This means that you can access arbitrary points in the array in
constant time by simply supplying an `index`, which under the hood is used as
an offset from the beginning of the array's address space. Concretely this
means that if the VM or compiler knows both how much memory is used for each
element in the array and what the address of the first value is, it can
produce instructions to find any element via index by simply moving
`index * num_bytes_per_element` from the start of the array.

A downside to this sequential storage approach is that adding or removing
elements anywhere besides the tail (end) of the array means that all of
the existing elements from the point of the operation on must be copied to
new addresses in order to keep the data in sequence. Eg, if you have 10
elements in an array and delete the 5th one, elements 6-10 must be copied
into positions 5-9. Similarly, if you have 10 elements and insert a new one
at position 5 (zero-based index 4) you must move elements 5-10 to positions
6-11 (and you must resize the array if its current capacity is only 10).

Finally, storing items at sequential addresses in memory provides good [locality
of reference](https://en.wikipedia.org/wiki/Locality_of_reference), meaning that
the computer can relatively easily store and re-use values from the array in its
CPU caches. More concretely, when a computer reads from memory, it typically grabs
as much data as it can process at once, rather than only grabbing the data at
the specific memory address requested.

So if we have an array `a` and we read out the value stored at `a[0]` a 64 bit
system might grab and 8 byte block of memory beginning at the address of `a[0]`.
The computer can then store that entire block in a CPU cache, which will be much
faster to access than going all the way back to memory.

This is good because, as mentioned in the locality of reference link above,
computer systems tend to access the same values repeatedly in a short span of
time, and they also tend to access things that are adjacent to one another in
memory.

What this means is that programs that access `a[0]` will be likely to reference
that value multiple times, and also will be likely to access data at `a[1]` and
`a[2]`. So one nice thing about arrays is that they make it easy for computer
hardware to optimize for those cases. Hooray!

+ Find/overwrite at index: O(1) - This runs in constant time, just move
`index * num_byte_per_element` from the start of the array and read or write the
value in question. In Ruby everything is an object and objects take up at most
a set number of bytes.

+ Find by value: O(n) - This runs in linear time because in the worst case you'll
need to iterate through the entire array, comparing the values of each element
to the value you're searching for.

+ Insert/delete and at end ("tail") of the array: O(1) to O(n) - In the average case this runs in constant time because
you're just writing or removing the value at the last address in memory (which
is easy to find, just move `(array_size - 1) * num_bytes_per_element` from the start
address of the array). _However_, as noted above, there are cases where this will
be much slower. If the array is already full when we try to insert an item, or
if the array has too much empty space when we delete an item a resizing will occur.
This requires that all of the existing elements in the array be copied over to
new space in memory.

+ Insert/delete not at the end of the array: O(n) - This is pretty slow! Operations
not at the end of the array run in linear time because all existing values must
be shifted over one place in memory. Why do we need to shift them? If we didn't
our formula for quickly accessing elements by index (moving
`index * num_bytes_per_element` from the start of the array) wouldn't work.

### Stacks, queues, and deques
As written, operations on the head/front of the array (shift and unshift)
operate in O(n) time because they are treated identically to operations
at the middle of the array. However these operations can be made to run in
constant time just like they are at the tail/end of the array.
To do this, when the array is initialized a pointer is kept to both the
first and last elements in the array (these point to the same address
initially), and memory is allocated such that there is address space to
either side of those pointers for values to be inserted into.
As the array runs out of space on either end we must be able resize it by
allocating memory on the appropriate side, expanding the array either
towards the right or the left depending on where the value was inserted.

This variation of the array data structure is one way of implementing a
Deque, or double-ended queue. Deques behave like both stacks (last in first out)
and queues (first in, first out).

Making your array behave like a deque can cause there to be more frequent
resizings (eg you could do one towards the right side, then on the very next
insert have to do one towards the left side) and more unused space (because some
empty space will tend to be kept both to the left and right ends).

So there are drawbacks, but if you need to be able to perform operations on
either end of the array efficiently, such as with a queue where new values
are pushed onto the right side and values are shifted off the left side,
then it is a good thing to do.

Ruby's Array class does allow for efficient operations on either end:
```ruby
require "benchmark"

a1 = Array.new(1_000_000) { rand }
a2 = Array.new(1_000_000) { rand }

queue_perf = Benchmark.realtime do
  1_000_000.times do
    rand > 0.5 ? a1.shift : a1.unshift(1)
  end
end

stack_perf = Benchmark.realtime do
  1_000_000.times do
    rand > 0.5 ? a2.pop : a2.push(1)
  end
end

puts queue_perf
# 0.10248183400017297

puts stack_perf
# 0.10594398699959129
```

## Linked lists
You can find the code for linked lists in `linked_list.rb` and the corresponding spec file.

Unlike an array, which always stores its values sequentially in
a contiguous block of memory addresses, linked lists do not need
to keep their values adjacent to one another. Instead they rely
on pointers from one node to the next/previous.

This means that they have worse locality of reference than arrays,
and therefore the underlying hardware is less able to cache
some contiguous block of memory with all the nodes in the list.

One trade-off there is that in a memory-constrained domain (the
data you want to keep in memory is very large relative to the
hardware) there must be a non-fragmented (contiguous) block of
memory large enough to accommodate all the values of an array,
whereas a linked list allows you to use all of the available
memory regardless of how fragmented it is.

+ Find: O(n) - Runs in linear time because in the worst case we need to traverse
he entire list from head to tail (or vice versa). There is no way to access
items by index as you would in an array, or by key as you would in a hash map.

+ Insert / Delete: O(1) - _Assuming you already have a reference to the node you
want to insert or delete_ these operations run in constant time because the only
work necessary is to adjust the references to/from the adjacent nodes.

## Hash maps
You can find the code for hash maps in `hash_map.rb` and the corresponding spec file.

Hash maps (AKA hash tables or just "hashes" in Ruby) can read, write, and
delete entries in O(1) (constant time) in the average case. However, in
the worst case these operations occur in O(n) (linear time) because of the
need for rehashing. What rehashing is an why it's necessary becomes apparent
once you understand how hash maps work under the hood.

In this implementation we will create a hash map by using the linked list and
dynamically resizing array data structures we've already built, along with a
crucial third piece: a hash function.

Hash functions take in some arbitrary data and output an integer value known
as a "hash", "hash digest", or "hash code" that has several useful properties:
1. It is always of the same number of digits
2. Its input value cannot be deduced from its output value.
3. It is uniformly random, meaning if the possible range of values for your
   hash function is 1-100, each of those numbers is equally likely to be
   produced. You won't get way more 50s than you will 2s.
4. It is always the same for a given input, meaning the hash function is
   deterministic.
5. There are few "collisions", which is when different inputs produce the
   same output.

Hash functions - if they are good - are also very fast. This is essential for
the efficacy of the hash map. This speed, along with points 3-5 above make the
hash map data structure possible.

We have written a very terrible hash function (`HashCode.for(value)`) for use
in this hash map class. It takes the underlying bytes of the string
representation of whatever you give it and squares them.
Real world hash functions will probably do more than that, possibly shifting
the sequence of bits or XORing the bits with some other, consistent string of
bits.

You can even encrypt data using a _cryptographic hash function_ that XORs the
bits you want to encrypt using a secret, pseudo-random sequence of bits (this is
the secret key in symmetric cryptography algorithms). But that's another topic
for another day. Google it, jeeze.

OK, back to hash maps. Hash maps take advantage of the fact that reading,
writing, or deleting the element at a given index in an array can happen
in constant time.

The obvious limitation to this feature of arrays is that in order to take
advantage of those constant time operations you must know the index of the
element you'd like to access.

So, hash maps use hash functions to provide a way of deducing the desired
array index given a "key" that identifies the value at that index.

Hash maps take the key and run it through their hash function, producing a
uniformly random integer hash digest for that key. They then use the modulus
operator `%` to produce an integer that is within the size of the array.
Eg, given a hash digest of 1001 and an array of size 10, `1001 % 10` gives
you `1`. We use this number as the array index for the key and its associated
value.

Because a hash function always outputs the same digest given the same input
we can look up this array index in the same way when it's time to read
a value from the hash map by its key.

But what about the hash collisions mentioned above? It is possible to produce
the same digest for multiple given inputs. To resolve such collisions we turn
to the linked list. At each index in the array, rather than directly storing
the value we want to write to the hash map, we store a linked list. Each node
in the linked list contains both the key and the value. If there is
a collision while writing to the hash map, we simply append another node to the
list with the new key-value pair.
When reading a value from the hash map we iterate through the linked list at
the appropriate array index until we find the key we are interested in.

You may be asking yourself: "if we have to iterate through a list, how do
hash maps have constant time lookups?". The answer is that we ensure there is
never a linked list with a large number of nodes to be iterated through.

This is where rehashing comes in. As we insert key-value pairs into the
hash map we increment a count. If the ratio of the number of key-value pairs
(entries) relative to the capacity of the array rises above a certain level known
as the [load factor](https://en.wikipedia.org/wiki/Hash_table#Key_statistics)
we will create a new, much larger, array and copy all of the existing values
to it. Given a good hash function, this makes sure that we never have to do
much iteration to find the key-value pair we are interested in.

Rehashing involves recalculating the hash and array index for every key,
because the size of the array is now different, and so the denominator in our
`hash_digest % array_size` function is also different.

Congratulations! Now you too can implement your own very, very terrible
hash map!

Now that we understand how they work, we are in a position to understand some
of the drawbacks to hash maps. Their guarantee of constant time operations in
the average case is very groovy indeed. But we know that because of the need
for rehashing every once and a while an insert operation will take linear
time. So if you have a performance-critical application and need to store
many thousands or millions of entries in memory and you cannot afford to have
any operations take linear time, then a hash map may *not* be the best choice.

Further, hash maps don't keep an kind of order to their entries. So you'll need
to do your own sorting if that's crucial to your application. This is more
important than it might seem at first glance.

Consider that most database indexes are binary search trees (BSTs) under the hood,
not hash maps. For example both [PostgreSQL](https://www.postgresql.org/docs/9.5/indexes-types.html)
and [MongoDB](https://docs.mongodb.com/manual/indexes/#id2) use BSTs as their
default index data structure.

Why? If you want to query the database using any kind of comparison operation
other than equality (AKA `SELECT name FROM people WHERE name = "fred"`) a hash
map will perform the search in linear time and therefore be useless as an index.
The hash map knows how to look up the value associated with the key "fred", but it
doesn't have an efficient way to compare the values of multiple keys with the value
"fred". Read the section below on binary search trees to learn more about the
many nice properties they provide.

Finally, hashes also have poor locality of reference because, like linked lists
they don't store values sequentially in memory.

## Binary search trees
You can find the code for hash maps in `avl_tree.rb` and the corresponding spec file.
AVL trees are a type of binary search tree that is _self-balancing_.

Self-balancing binary search trees perform reads, writes, and deletes in
O(log n) _in the worst case_. So if avoiding slow operations is imperative to
your application then  you may want a tree rather than a hash map, despite the
tree's slower average operation time.

Further, trees order nodes as they are inserted, so you easily can traverse
the entire tree in sorted order in log(n) time.

But wait, what's a binary search tree, and why does it need to be self-balancing?
Whatever that means.

### Binary search
You may already be familiar with the binary search algorithm. It's simple but
powerful. If you have some set of data in sorted order you can use binary search
for a given value in log(n) time. To put that in perspective log base 2 of 1,000,000
is roughly 20. So that's _at most_ 20 operations to find a particular value in a
data set of one million entries. Noice!

Binary search starts at the middle value (the halfway point of the sorted data)
and compares the value it finds there to the one it's looking for. If it doesn't
find a matching value there it repeats the process, but this time it searches only
half of the data: if the middle value was greater than the value being searched
for then the search is repeated to the left of the middle value, otherwise it is
repeated on the data to the right (assuming the data was sorted in ascending order).

You repeat this process as many times as necessary, effectively ignoring half
of the remaining data on each iteration.

So what's the problem with just using a sorted array and doing binary search
when you want to find something? The problem is that, as discussed above, when
you want to insert or delete an element from the array it can be very slow
depending on how full the array is and at what position in the array you're
operating.

### Trees
Binary search trees solve this by organizing data in nodes that link to up to
two child nodes. Every node has a value. If a node is a left-hand child of a given
parent node, its value is less than its parent's. If a node is right-hand child
of a parent node then its value is greater than than that of its parent's.

With trees a picture is worth a thousand words:
```ruby
t = AVLTree.new

t.insert(5)
t.insert(7)
t.insert(1)
t.insert(-3)
t.insert(33)
t.insert(7)
t.insert(9)
#            5
#          /   \
#         1     7
#        /     / \
#      -3     7   33
#                /
#               9
```

Binary search trees combine the good properties of a linked list and doing a
binary search on a sorted array. You can find a node in log(n) time via binary
search by starting at the root node (the top of the tree) and navigating left
if the value you want is less than the node's value, and going to the right
if the value you're looking for is greater.

However, once you've found a given node in the tree deleting it, or inserting one
above or below it occurs in constant time just like with a linked list! All you
need to do is update the references from one node to another.

Thus, all operations occur in roughly log(n) time.

### Rebalancing via tree rotations
Tree rotations are a mechanism for our tree to self-balance, which prevents our
tree from becoming *degenerate*. That is, as nodes are inserted and deleted
some sections ("subtrees") of the tree may become much deeper than others.

To see why this is a problem imagine the extreme case:
a "tree" where all child nodes are the right-hand child of their parent.
This is just a linked list, which takes O(n) to find any given node.
Eg, a degenerate binary search tree that is essentially just a linked list:
```
1
 \
  2
   \
    3
```
Rotations move nodes around such that no subtree is more than one layer deeper/
taller than its sibling subtree. The term "rotation" makes visual sense as you
typically adjust the nodes so that a child from one side comes up to occupy the
position the parent is currently in, and the parent is moved down and over to
the side opposite the one that first node came from. Eg, our degenerate tree
above can be rotated so that 2 comes up to where 1 is, and 1 moves down and over
to the left side:
```
  2
 / \
1   3
```

But how do we know when to perform a rotation? First, we specify an
*invariant* constraint for the system. This is just a rule that we want to
never be violated. For AVL trees the invariant is that no node should have
one subtree be more than 1 layer deeper/taller than its sibling subtree.

Next, we keep track of a *balance* attribute on each node, and adjust the
balances of relevant nodes whenever a node is inserted or deleted from the
tree. When that happens we traverse up the tree from the node that was
inserted/deleted adjusting the balances of each ancestor node along the way.
If at any point we encounter a node whose updated balance would violate our
constraint we perform the appropriate rotation for that node's subtrees.

Depending on the shape of the subtree the rotations look a little different.
These specs demonstrate how rotations work for different shapes of subtrees.

Confused? Here's a great [visualization](https://www.cs.usfca.edu/~galles/visualization/AVLtree.html)
of tree rotations from the University of San Francisco.
