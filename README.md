# MemStore

*A simple in-memory data store.*

MemStore is a simple in-memory data store that supports adding, retrieving and deleting items as well as complex search queries and easy serialization.

It’s not in any way supposed to be a “real” database. However, it can replace a database in small applications or prototypes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "memstore"
```

And then execute:

```sh
$ bundle
```

Or install it yourself:

```sh
$ gem install memstore
```

## Usage

- [Objects vs. Hashes](#objects-vs-hashes)
- [Adding Items](#adding-items)
- [Getting Items](#getting-items)
- [Finding Items](#finding-items)
- [Deleting Items](#deleting-items)
- [Counting Items](#counting-items)

Creating a data store is utterly simple:

```ruby
store = MemStore.new
```

By default, objects are indexed using `Object#hash`.

If a different property should be used, it can be specified like this:

```ruby
store = MemStore.new(:id)
```

The property needs to be truly unique for all objects since it’s used as a hash key internally.

### Objects vs. Hashes

MemStore comes in two flavors: `ObjectStore` and `HashStore`.

They’re basically the same, but `ObjectStore` accesses items through `item.attribute` while `HashStore` accesses items through `item[attribute]`.

`ObjectStore` is the default variant:

```ruby
store = MemStore.new
# is equal to
store = MemStore::ObjectStore.new
```

`HashStore` needs to be created explicitly:

```ruby
store = MemStore::HashStore.new
```

If no key attribute is specified, `HashStore` will also use `Object#hash`.

### Adding Items

`add` adds one or multiple items and returns the data store itself:

```ruby
store.add(a, b, c)
# => store
```

Since it returns the data store, items can be added right after instantiation:

```ruby
store = MemStore.new.add(a, b, c)
# => store
```

MemStore also supports the shovel operator `<<` for adding items.  
Only one item can be added at a time but it’s chainable:

```ruby
store << a << b << c
# => store
```

### Getting Items

`items` provides direct access to the internal items hash.

```ruby
store.items
# => {}
store.items = { 1 => a, 2 => b, 3 => c }
# => { 1 => a, 2 => b, 3 => c }
```

`get` is used to look up items by their key.  
If a single key is given, a single item will be returned.  
If multiple keys are given, an array of items will be returned with `nil` where there is no item for a key.

```ruby
store.get(1)
# => a
store.get(1, 2, 3)
# => [a, b, c]
```

This can also be done using the bracket operator `[]`:

```ruby
store[1]
# => a
store[1, 2, 3]
# => [a, b, c]
```

Ranges are also supported and can even be combined with single keys:

```ruby
store[1..3]
# => [a, b, c]
store[1..3, 6]
# => [a, b, c, f]
```

### Finding Items

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

### Deleting Items

Items can be deleted directly by key or by reference.

`delete_item` deletes a single items and returns it or nil if the item didn’t exist.  
`delete_items` deletes multiple items and returns an array of them with `nil` where an item didn’t exist.  
`delete_key` and `delete_keys` work similarly, but take keys instead of items.

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

### Counting Items

`size` returns the current number of items:

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

## Contributing

1. Fork it on [GitHub](https://github.com/sklppr/memstore).
2. Create a feature branch containing your changes:

    ```sh
    $ git checkout -b feature/my-new-feature
    # code, code, code
    $ git commit -am "Add some feature"
    $ git push origin feature/my-new-feature
    ```

3. Create a Pull Request on [GitHub](https://github.com/sklppr/memstore).
