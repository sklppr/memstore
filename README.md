# MemStore

*A simple in-memory data store.*

MemStore is a simple in-memory data store that supports complex search queries.

It’s not in any way supposed to be a database. However, it can be used instead of database in small applications or prototypes.

**Important: Ruby 2.1 is required.**

## Basics

Creating a data store is straightforward:

```ruby
store = MemStore.new
# => store
```

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

## Queries

MemStore provides methods to find, count and delete items using complex queries:

- `find_*` returns all items matching the query
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
- `first` is an alias of `first_all`
- `count` is an alias of `count_all`
- `delete` is an alias of `delete_all`

### Conditions

All methods take a hash of conditions and/or a block.

The hash is expected to map attributes (see [Customization](#customization)) to conditions.  
Conditions are evaluated using the case equality operator: `condition === item`

This means conditions can be virtually anything:

```ruby
store.find(name: "John", age: 42)
# is equivalent to item.name == "John" && item.age == 42
store.find(name: /^Jo/, age: 23..42)
# is equivalent to /^Jo/ =~ item.name && (23..42).include?(item.age)
store.find(child: MyClass)
# is equivalent to item.child.kind_of?(MyClass)
store.find(child: -> child { child.valid? })
# is equivalent to proc.call(item.child)
```

You can enable additional types of conditions simply by implementing `===`.  
For example, MemStore also supports arrays using an internal refinement:

```ruby
store.find(age: [23, 25, 27])
# is equivalent to [23, 25, 27].include?(item.age)
```

The implementation looks like this:

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
# is equivalent to item.age == 25 && item.age - item.child.age > 20
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

## Map & Reduce

MemStore provides a `map` method which is a shortcut to `store.all.map`:

```ruby
store.map { |item| "#{item.name} (#{item.age})" }
# => ["Peter (23)", "Paul (42)", "Mary (33)"]
```

Since the result is an array, you can directly call `reduce` on it:

```ruby
store.map { |item| item.name.length }.reduce { |sum, n| sum + n }
# => 13
```

If you simply want to grab a certain attribute from each item, you can use `collect` instead:

```ruby
store.collect(:age)
# is equivalent to
store.map { |item| item.age }
```

This automatically uses the correct access method for attributes (see [Customization](#customization)).

It also returns an array so you can directly chain `reduce`:

```ruby
store.collect(:age)
# => [23, 42, 33]
store.collect(:age).reduce(:+)
# => 98
```

*Of course, you can also use `items` or `all` to directly work with a hash or array of items.*

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

*Note that using strings will result in a performance penalty because `Object#send` expects symbols.*

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
*Note that providing a string will result in a performance penalty because `Object#send` expects symbols.*

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

If you want to do something special to obtain a key, you can provide a Proc or Method.  
It will be passed the item for which MemStore needs a key and is expected to return a truly unique identifier for that item:

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

Note that this is also a way to circumvent the access method for attributes.  
For example, you might want to use one method `get` to access all attributes but a different method `id` should be used for indexing:

```ruby
# this way, item.get(:id) would be used:
store = MemStore.new(access: :get, key: :id)
# circumvent the access method like this:
store = MemStore.new(access: :get, key: -> item { item.id })
# or even shorter:
store = MemStore.new(access: :get, key: Proc.new(&:id))
store << item
# calls item.id to retrieve key
store.find(age: 42, name: "John")
# calls item.get(:age) and item.get(:name) to retrieve attributes
```

Likewise, you can provide a Proc or Method to be called when accessing attributes.  
It will be passed both the item in question and the attribute to be retrieved and is expected to return the appropriate value:

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
