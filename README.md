# MemStore

*A simple in-memory data store.*

MemStore is a simple in-memory data store that supports complex search queries. It’s not in any way supposed to be a database. However, it can be used instead of database in small applications or prototypes.

The philosophy behind MemStore is that pure Ruby already gives you several advanced features like complex query logic for finding/counting/deleting items, set operations, map/reduce operations, lazy enumeration and serialization.

MemStore provides a thin layer of abstraction to make these things easier to use and lots of examples of how common use cases can be realized.

**Ruby 2.1+ is required.**

## Basics

Creating a data store is straightforward:

```ruby
store = MemStore.new
# => store
```

### Adding Items

Adding items is equally simple. Add a single item using the shovel operator `<<` or multiple items using `add`:

```ruby
store << a
# => store
store.add(a, b, c)
# => store
```

To make things easier, MemStore’s constructor takes a collection of items that will be added right away:

```ruby
store = MemStore.new(items: [a, b, c])
# => store
```

### Accessing Items

You can access single items by their key (see [Customization](#customization)) using the bracket operator `[]` or multiple items using `get`:

```ruby
store[1]
# => a
store.get(1, 2, 3)
# => [a, b, c]
```

You can also get all items at once using `all` and a hash of all items with their keys using `items`:

```ruby
store.all
# => [a, b, c]
store.items
# => { 1 => a, 2 => b, 3 => c }
```

### Deleting Items

Items can be deleted by reference, either one or multiple items can be deleted at the same time.
All methods return items that were deleted or nil where an item couldn’t be found.

```ruby
store.delete_item(a)
# => a
store.delete_items(a, xyz, b)
# => [a, nil, b]
```

Similarly to the above, items can also be deleted by key:

```ruby
store.delete_key(1)
# => obj
store.delete_keys(1, -99, 2)
# => [a, nil, b]
```

## Queries

MemStore provides methods to find, count and delete items using complex queries:

- `find_*` returns all items matching the query
- `lazy_find_*` returns a lazy enumerator of all items matching the query
- `first_*` returns the first item matching the query
- `count_*` returns the number of items matching the query
- `delete_*` deletes and returns all items matching the query

These methods have one of the following suffixes:

- `*_all` matches items *fulfilling all* conditions
- `*_any` matches items *fulfilling at least one* condition
- `*_one` matches items *fulfilling exactly one* condition
- `*_not_all` matches items *violating at least one* condition
- `*_none` matches items *violating all* conditions

In other words:

- `all` means `condition && condition && ...`
- `any` means `condition || condition || ...`
- `one` means `condition ^ condition ^ ...`
- `not all` means `!(condition && condition && ...)` or `!condition || !condition || ...`
- `none` means `!(condition || condition || ...)` or `!condition && !condition && ...`

For convenience, there are aliases for the `*_all` variants:

- `find` is an alias of `find_all`
- `lazy_find` is an alias of `lazy_find_all`
- `first` is an alias of `first_all`
- `count` is an alias of `count_all`
- `delete` is an alias of `delete_all`

All methods take a hash of conditions and/or a block. 

### Conditions

The conditions hash is expected to map attributes (see [Customization](#customization)) to criterions. Conditions are evaluated using the case equality operator `criterion === value` and can be virtually anything.

Objects like strings and numbers will be compared:

```ruby
store.find(name: "John", age: 42)
# equivalent to item.name == "John" && item.age == 42
```

Arrays and ranges will be checked for inclusion:

```ruby
store.find(age: [23, 25, 27], height: 170..180)
# equivalent to [23, 25, 27].include?(item.age) && (170..180).include?(item.height)
```

Regular expressions will be evaluated:

```ruby
store.find(name: /^Jo/, age: 23..42)
# equivalent to /^Jo/ =~ item.name && (23..42).include?(item.age)
```

Classes will be compared (also matches on subclasses):

```ruby
store.find(child: MyClass)
# equivalent to item.child.kind_of?(MyClass)
```

Blocks will be invoked with the attribute value:

```ruby
store.find(child: -> child { child.valid? })
# equivalent to proc.call(item.child)
```

You can enable additional types of conditions simply by implementing `===`.  
For example, arrays are supported using refinements like this one:

```ruby
refine Array do
  def ===(obj)
    include?(obj)
  end
end
```

### Block

The block is invoked with the item *after* the conditions are evaluated.

```ruby
store.find(age: 25) { |item| item.age - item.child.age > 20 }
# equivalent to item.age == 25 && item.age - item.child.age > 20
```

### Operators

Since all queries return arrays, you can use set operations.  
This can be especially useful to avoid overly complex queries.

Assume queries with these results:

```ruby
store.find_any(...)
# => [a, b, c, d, e]
store.find_all(...)
# => [a, b, c]
store.find_none()
# => [b, c, e]
```

Combine results using the union operator `|`:

```ruby
store.find_all(...) | store.find_none(...)
# => [a, b, c, e]
```

Restrict results using the intersection operator `&`:

```ruby
store.find_any(...) & store.find_none(...)
# => [a, d]
```

Note that both operators exclude duplicates and preserve order.

### Collection Operations

MemStore provides a shortcut to collect attribute values from all items. The result is an array and could also be used for map/reduce operations.

```ruby
store.collect(:age)
# => [23, 42, 33]
store.collect(:age).reduce(:+)
# => 98
```

This shortcut automatically uses the correct access method for attributes (see [Customization](#customization)).

Of course, you can use `store.items` or `store.all` to directly work with the hash or array of items:

```ruby
store.all.map { |item| "#{item.name} (#{item.age})" }
# => ["Peter (23)", "Paul (42)", "Mary (33)"]
store.all.reduce(0) { |sum, item| sum + item.age }
# => 98
```

## Customization

### Default Behavior

By default, MemStore indexes items using `Object#hash`:

```ruby
store = MemStore.new
store << item
# calls item.hash to retrieve key
store[item.hash]
# => item
```

When you use `find_*`, `first_*`, `count_*` or `delete_*`, MemStore calls attributes as methods on your items using `Object#send`:

```ruby
store = MemStore.new
store << item
store.find(age: 42, name: "John")
# calls item.age and item.name to retrieve attributes
```

This means that it doesn’t make a difference whether you use strings or symbols in the conditions hash:

```ruby
store.find("age" => 42, "name" => "John")
# calls item.age and item.name to retrieve attributes
```

### Custom Key

You’ll probably want MemStore to use a specific attribute to index items.  
This is possible using the `key` parameter when creating a data store:

```ruby
store = MemStore.new(key: :id)
store << item
# calls item.id to retrieve key
store[item.id]
# => item
```

Whatever you provide as `key` will be treated as an attribute.  
So, by default, the according method will be called on your item.

### Custom Access Method

If you want to change how attributes are accessed, you can use the `access` parameter when creating a data store:

```ruby
store = MemStore.new(key: :id, access: :[])
# now you can store hashes, e.g. { id: 5, age: 42, name: "John" }
store << item
# calls item[:id] to retrieve key
store.find(age: 42, name: "John")
# calls item[:age] and item[:name] to retrieve attributes
```

If you provide a symbol or string, it will be treated as a method name.  

To access an attribute, MemStore will call the according method on your item and pass the requested attribute to it.  
This means `key` and attributes in the conditions hash must be whatever your method expects:

```ruby
# assuming that items have a method `get` that expects a string:
store = MemStore.new(key: "id", access: :get)
store << item
# calls item.get("id") to retrieve key
store.find("age" => 42, "name" => "John")
# calls item.get("age") and item.get("name") to retrieve attributes
```

### Advanced Customization

If you want to do something special to obtain an attribute, you can provide a Proc or Method. It will be passed both the item in question and the attribute to be retrieved and is expected to return the appropriate value:

```ruby
def special_accessor(item, attribute)
  # ...
end

# lambda:
store = MemStore.new(access: -> item, attribute { special_accessor(item, attribute) })
# Proc:
store = MemStore.new(access: Proc.new { |item, attribute| special_accessor(item, attribute) })
# Method:
store = MemStore.new(access: method(:special_accessor))
```

Likewise, you can provide a Proc or Method to be called when accessing keys. It will be passed the item for which MemStore needs a key and is expected to return a truly unique identifier for that item:

```ruby
def special_hash(item)
 # ...
end

# lambda:
store = MemStore.new(key: -> item { special_hash(item) })
# Proc:
store = MemStore.new(key: Proc.new { |item| special_hash(item) })
# Method:
store = MemStore.new(key: method(:special_hash))
```

This is also a way to use a different access method for keys than for other attributes. For example, you might want to use a method `get` to access attributes but a different method `id` should be used to obtain keys:

```ruby
# this way, item.get(:id) would be used:
store = MemStore.new(access: :get, key: :id)
# circumvent the access method like this:
store = MemStore.new(access: :get, key: -> item { item.id })
# or even shorter:
store = MemStore.new(access: :get, key: Proc.new(&:id))
# calls item.id to retrieve key
store.find(age: 42, name: "John")
# calls item.get(:age) and item.get(:name) to retrieve attributes
```
