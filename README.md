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

Or install it yourself as:

```sh
$ gem install memstore
```

## Usage

- [Basics](#basics)
- [Objects vs. Hashes](#objects-vs-hashes)
- [Adding Items](#adding-items)
- [Retrieving Items](#retrieving-items)
- [Deleting Items](#deleting-items)
- [Search Queries](#search-queries)
- [Serialization](#serialization)
  - [Binary](#binary)
  - [Hash](#hash)
  - [YAML](#yaml)
  - [JSON](#json)
  - [MessagePack](#messagepack)

### Basics

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

An items collection can also be provided on creation:

```ruby
store = MemStore.new(nil, { ... }) # to use Object.hash as key
store = MemStore.new(:id, { ... }) # to use custom key
```

The collection must be a hash that correctly maps the used key to each item.

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

`items` provides direct access to the internal items hash.

```ruby
store.items
# => {}
store.items = { 1 => a, 2 => b, 3 => c }
# => { 1 => a, 2 => b, 3 => c }
```

`insert` adds one or multiple items and returns the data store itself:

```ruby
store.insert(a, b, c)
# => store
```

Since it returns the data store, items can be added right after instantiation:

```ruby
store = MemStore.new.insert(a, b, c)
# => store
```

MemStore also supports the shovel operator `<<` for adding items.  
Only one item can be added at a time but it’s chainable:

```ruby
store << a << b << c
# => store
```

### Retrieving Items

`length` (or `size`) returns the current number of items:

```ruby
store.length
# => 3
```

The bracket operator `[]` is used to look up items by their key.  
If a single key is given, a single item will be returned.  
If multiple keys are given, an array of items will be returned with `nil` when there is no item for a key.

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

### Deleting Items

`delete_items` (or `delete_item`) deletes items by reference and returns them.  
This is considered the default use case and therefore also available as `delete`.

If one item is given, it is deleted and returned.  
If multiple items are given, they are deleted and returned as an array.

```ruby
store.delete_item(a)
# => a
store.delete_items(b, c, d)
# => [b, c, d]
store.delete(e, f, g)
# => [e, f, g]
```

This is considered the default use case and therefore also available as `delete`.

`delete_keys` (or `delete_key`) deletes items by key and returns them.  
Again, one or multiple items can be deleted at a time and even ranges are accepted.

```ruby
store.delete_key(1)
# => a
store.delete_keys(2, 3, 4)
# => [b, c, d]
store.delete_keys(5..7, 9)
# => [e, f, g, i]
```

### Search Queries

The following methods are available to query the data store:

- `find_all` (also available as `find`)
- `find_any`
- `find_one`
- `find_not_all`
- `find_none`
- `first_all` (also available as `first`)
- `first_any`
- `first_one`
- `first_not_all`
- `first_none`
- `count_all` (also available as `count`)
- `count_any`
- `count_one`
- `count_not_all`
- `count_none`

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
- `one` means `condition ^ condition ^ ...` (XOR).
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

### Serialization

MemStore support various ways of de-/serializing the data store.

- `ObjectStore` supports binary format.
- `HashStore` supports binary format, hash, [YAML](http://yaml.org/), [JSON](http://www.json.org/) and [MessagePack](http://msgpack.org/).

**Important:** When file IO or deserialization fails, all variants of `from_*` return `nil`.

The following style ensures that there will be a (correctly configured) data store:

```ruby
store = MemStore.from_file(file) || MemStore::HashStore(key, items)
```

#### Binary

Both `ObjectStore` and `HashStore` can easily be serialized to and from binary format:

```ruby
store.to_binary
# => binary string
store.to_file(file)
# => number of bytes written
MemStore.from_binary(binary)
# => instance of ObjectStore or HashStore or nil
MemStore.from_file(file)
# => instance of ObjectStore or HashStore or nil
```

#### Hash

`HashStore` can be converted to and from a hash:

```ruby
store.to_hash
# => { key: ..., items: { ... } }
MemStore::HashStore.from_hash(hash)
# => instance of HashStore or nil
```

#### YAML

`memstore/yaml` enables serialization of `HashStore` to and from [YAML](http://yaml.org/):

```ruby
require "memstore/yaml" # requires "yaml"

store.to_yaml
# => YAML string
store.to_yaml_file(file)
# => number of bytes written
MemStore::HashStore.from_yaml(yaml)
# => instance of HashStore or nil
MemStore::HashStore.from_yaml_file(file)
# => instance of HashStore or nil
```

De/serialization is seamless since YAML can handle symbols and non-string keys (i.e. Psych converts them correctly).

#### JSON

`memstore/json` enables serialization of `HashStore` to and from [JSON](http://www.json.org/):

```ruby
require "memstore/json" # requires "json"

store.to_json
# => JSON string
store.to_json_file(file)
# => number of bytes written
MemStore::HashStore.from_json(json)
# => instance of HashStore or nil
MemStore::HashStore.from_json_file(file)
# => instance of HashStore or nil
```

**Important:** Symbols will be converted to strings and JSON only allows string keys.

```ruby
store = MemStore::HashStore.new(:id)
store << { id: 1 }
store.to_hash
# => { :key => :id, :items => { 1 => { :id => 1 } } }
store = MemStore::HashStore.from_json(store.to_json)
store.to_hash
# => { :key => "id", :items => { "1" => { "id" => 1 } } }
```

The following style ensures consistent access before and after serialization:

```ruby
store = MemStore::HashStore.new("id")
store << { "id" => "1" }
store["1"]
# => { "id" => "1" }
```

#### MessagePack

`memstore/msgpack` enables serialization of `HashStore` to and from [MessagePack](http://msgpack.org/):

```ruby
require "memstore/msgpack" # requires "msgpack"

store.to_msgpack
# => MessagePack binary format
store.to_msgpack_file(file)
# => number of bytes written
MemStore::HashStore.from_msgpack(msgpack)
# => instance of HashStore or nil
MemStore::HashStore.from_msgpack_file(file)
# => instance of HashStore or nil
```

**Important:** Symbols will be converted to strings but non-string keys are allowed.

```ruby
store = MemStore::HashStore.new(:id)
store << { id: 1 }
store.to_hash
# => { :key => :id, :items => { 1 => { :id => 1 } } }
store = MemStore::HashStore.from_msgpack(store.to_msgpack)
store.to_hash
# => { :key => "id", :items => { 1 => { "id" => 1 } } }
```

The following style ensures consistent access before and after serialization:

```ruby
store = MemStore::HashStore.new("id")
store << { "id" => 1 }
store[1]
# => { "id" => 1 }
```

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
