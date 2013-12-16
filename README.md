# MemStore

*A simple in-memory data store.*

MemStore is a simple in-memory data store that supports complex search queries.

It’s not in any way supposed to be a database. However, it can be used instead of database in small applications or prototypes.

**Note: Ruby 2.0 is required.**

## Initialization

Creating a data store is utterly simple:

```ruby
store = MemStore.new
```

If the store should contain items right away, they can be passed as an array:

```ruby
store = MemStore.new(items: [a, b, c])
```

## Customization

The way the data store indexes items and accesses their attributes can be customized so that arbitrary data can be stored.

```ruby
store = MemStore.new(key: ..., access: ...)
```

By default, MemStore will call `item.hash` to obtain a unique identifier.

If something provided for `key`, it will be used as a parameter to the `access` method.  
In most cases, this will be a Symbol or String:

```ruby
store = MemStore.new(key: :id)
# store will try to access attribute :id
store = MemStore.new(key: "id")
# store will try to access attribute "id"
```

However, if a Proc or Method is provided, it will be called and passed the item:

```ruby
store = MemStore.new(key: -> item { ... })
# or
store = MemStore.new(key: Proc.new { |item| ... })
# or
def get_custom_key(item)
  ...
end
store = MemStore.new(key: method(:get_custom_key))
```

By default, MemStore will access attributes as methods, i.e. using `item.send(attribute)`:

```ruby
store = MemStore.new(key: :id)
# store will call item.id to obtain key
```

If something is provided for `access`, it will be used as a method identifier which will be called and passed the attribute:

```ruby
store = MemStore.new(key: :id, access: :get)
# store will call item.get(:id) to obtain key
```

However, if a Proc or Method is provided, it will be called and passed the item and attribute:

```ruby
store = MemStore.new(access: -> item, attribute { ... })
# or
store = MemStore.new(access: Proc.new { |item, attribute| ... })
# or
def extract_attribute(item, attribute)
  ...
end
store = MemStore.new(access: method(:extract_attribute))
```

Using these two options, a multitude of variants can be configured, e.g.:

```ruby
# Use item.hash and item.attribute
store = MemStore.new
# Use item.hash and item.get(attribute)
store = MemStore.new(access: :get)
# Store hashes: use item[attribute] and :id as key
store = MemStore.new(access: :[], key: :id)
# Use one method for all attributes but a special method for key
store = MemStore.new(access: :get, key: -> item { item.key })
```

## Adding Items

Single items can be added using the shovel operator `<<`:

```ruby
store << a
# => store
```

Multiple items can be added using `add`:

```ruby
store.add(a, b, c)
# => store
```

## Getting Items

Single items can be accessed by their key using the bracket operator `[]`:

```ruby
store[1]
# => a
```

Multiple items can be retrieved using `get`, which always returns an array:

```ruby
store.get(1)
# => [a]
store.get(1, 2, 3)
# => [a, b, c]
```

The array contains `nil` when there is no item for a key:

```ruby
store.get(1, -1, 3)
# => [a, nil, c]
```

`items` provides direct read/write access to the internal items hash:

```ruby
store.items
# => {}
store.items = { 1 => a, 2 => b, 3 => c }
# => { 1 => a, 2 => b, 3 => c }
```

## Finding Items

The following methods are available to query the data store:

- `find_all` (alias `find`)
- `find_any`
- `find_one`
- `find_not_all`
- `find_none`
- `first_all` (alias `first`)
- `first_any`
- `first_one`
- `first_not_all`
- `first_none`

The first part indicates what is returned:

- `find_*` returns all matches.
- `first_*` returns the first match.
- `count_*` returns the number of matches.

The second part indicates how conditions are evaluated:

- `*_all` matches items *fulfilling all* conditions.
- `*_any` matches items *fulfilling at least one* condition.
- `*_one` matches items *fulfilling exactly one* condition.
- `*_not_all` matches items *violating at least one* condition.
- `*_none` matches items *violating all* conditions.

In other words:

- `all` means `condition && condition && ...`.
- `any` means `condition || condition || ...`.
- `one` means `condition ^ condition ^ ...`.
- `not all` means `!(condition && condition && ...)` or `!condition || !condition || ...`.
- `none` means `!(condition || condition || ...)` or `!condition && !condition && ...`.

All variants take a `conditions` hash and an optional block.

The hash maps attributes names to conditions that should be tested.  
Conditions are evaluated using the `===` operator and can be virtually anything:

```ruby
store.find(name: "Fred", age: 25)
store.find(name: /red/i, age: 10..30)
store.find(child: MyClass)
store.find(child: -> child { child.valid? })
```

Additional types can be used in conditions by supporting the `===` operator. For example:

```ruby
class Array
  def ===(obj)
    self.include?(obj)
  end
end

store.find(age: [23, 25, 27])
```

The block is invoked with the item *after* the conditions are evaluated. It should return a boolean value:

```ruby
store.find(age: 25) { |item| item.age - item.child.age > 20 }
# is evaluated as (item.age == 25) && (item.age - item.child.age > 20)
```

In addition to the evaluation logic, the arrays returned by all variants of `find_*` can be merged:

```ruby
store.find(...) | store.find(...) | store.find(...)
```

Note that the pipe operator `|` already eliminates duplicates:

```ruby
[a, b, c] | [c, d, e]
# => [a, b, c, d, e]
```

## Deleting Items

Items can be deleted directly by key or by reference.

`delete_item` deletes a single items and returns the item or nil if the item didn’t exist.  
`delete_items` deletes multiple items and returns an array of them with `nil` where an item didn’t exist.  
`delete_key` and `delete_keys` work similarly, except using keys instead of items.

```ruby
store.delete_item(a)
# => a
store.delete_items(b, c, d)
# => [b, c, d]
store.delete_key(5)
# => e
store.delete_keys(6, 7, 8)
# => [f, g, h]
```

Similar to the `find_*` and `count_*` methods, the following methods are available to delete items:

- `delete_all` (alias `delete`)
- `delete_any`
- `delete_one`
- `delete_not_all`
- `delete_none`

All methods return an array of items that were deleted from the data store.

## Counting Items

`size` returns the current number of items in the data store:

```ruby
store.size
# => 3
```

Similar to the `find_*` methods, the following methods are available to count items:

- `count_all` (alias `count`)
- `count_any`
- `count_one`
- `count_not_all`
- `count_none`
