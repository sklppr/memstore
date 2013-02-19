# MemStore

*A simple in-memory data store.*

MemStore is a simple in-memory data store that supports adding, retrieving and deleting items as well as complex search queries and easy serialization.

It’s not in any way supposed to be a “real” database. However, it can replace a database in small applications or prototypes.

## Installation

Add this line to your application's Gemfile:

    gem "memstore"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install memstore

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
mb = MemStore.new
```

By default, objects are indexed using `Object#hash`.

If a different property should be used, it can be specified like this:

```ruby
mb = MemStore.new(:id)
```

The property needs to be truly unique for all objects since it’s used as a hash key internally.

An items collection can also be provided on creation:

```ruby
mb = MemStore.new(nil, { ... }) # to use Object.hash as key
mb = MemStore.new(:id, { ... }) # to use custom key
```

The collection must be a hash that correctly maps the used key to each item.

### Objects vs. Hashes

MemStore comes in two flavors: `ObjectStore` and `HashStore`.

They’re basically the same, but `ObjectStore` accesses items through `item.attribute` while `HashStore` accesses items through `item[attribute]`.

`ObjectStore` is the default variant:

```ruby
mb = MemStore.new
# is equal to
mb = MemStore::ObjectStore.new
```

`HashStore` needs to be created explicitly:

```ruby
mb = MemStore::HashStore.new
```

If no key attribute is specified, `HashStore` will also use `Object#hash`.

### Adding Items

`items` provides direct access to the internal items hash.

```ruby
mb.items
# => {}
mb.items = { 1 => a, 2 => b, 3 => c }
# => { 1 => a, 2 => b, 3 => c }
```

`insert` adds one or multiple items and returns the data store itself:

```ruby
mb.insert(a, b, c)
# => mb
```

Since it returns the data store, items can be added right after instantiation:

```ruby
mb = MemStore.new.insert(a, b, c)
# => mb
```

MemStore also supports the shovel operator `<<` for adding items.  
Only one item can be added at a time but it’s chainable:

```ruby
mb << a << b << c
# => mb
```

### Retrieving Items

`size` returns the current number of items:

```ruby
mb.size
# => 3
```

The bracket operator `[]` is used to look up items by their key.  
If a single key is given, a single item will be returned.  
If multiple keys are given, an array of items will be returned with `nil` when there is no item for a key.

```ruby
mb[1]
# => a
mb[1, 2, 3]
# => [a, b, c]
```

Ranges are also supported and can even be combined with single keys:

```ruby
mb[1..3]
# => [a, b, c]
mb[1..3, 6]
# => [a, b, c, f]
```

### Deleting Items

`delete_items` (or `delete_item`) deletes items by reference and returns them.  
This is considered the default use case and therefore also available as `delete`.

If one item is given, it is deleted and returned.  
If multiple items are given, they are deleted and returned as an array.

```ruby
mb.delete_item(a)
# => a
mb.delete_items(b, c, d)
# => [b, c, d]
mb.delete(e, f, g)
# => [e, f, g]
```

This is considered the default use case and therefore also available as `delete`.

`delete_keys` (or `delete_key`) deletes items by key and returns them.  
Again, one or multiple items can be deleted at a time and even ranges are handled.

```ruby
mb.delete_key(1)
# => a
mb.delete_keys(2, 3, 4)
# => [b, c, d]
mb.delete_keys(5..7, 9)
# => [e, f, g, i]
```

### Search Queries

The following methods are available to query the data store:

- `find_all` (`find`)
- `find_any`
- `find_one`
- `find_not_all`
- `find_none`
- `first_all` (`first`)
- `first_any`
- `first_one`
- `first_not_all`
- `first_none`

The first part indicates what is returned:

- `find_*` returns all matches.
- `first_*` returns the first match.

The second part indicates how conditions are evaluated:

- `*_all` matches items *fulfilling all* conditions.
- `*_any` matches items *fulfilling at least one* condition.
- `*_one` matches items *fulfilling exactly one* condition.
- `*_not_all` matches items *violating at least one* condition.
- `*_none` matches items *violating all* conditions.

In other words:

- `all` means `condition && condition && ...`
- `any` means `condition || condition || ...`
- `one` means `condition ^ condition ^ ...` (XOR)
- `not all` means `!(condition && condition && ...)` or `!condition || !condition || ...`
- `none` means `!(condition || condition || ...)` or `!condition && !condition && ...`

For convenience, `find` is aliased to `find_all` and `first` to `first_all`.

All variants take a `conditions` hash and an optional block.

The hash maps attributes names to conditions that should be tested.  
Conditions are evaluated using the `===` operator and can be virtually anything:

```ruby
mb.find(name: "Fred", age: 25)
mb.find(name: /red/i, age: 10..30)
mb.find(child: MyClass)
mb.find(child: -> child { child.valid? })
```

Additional types can be used in conditions by supporting the `===` operator. For example:

```ruby
class Array
	def ===(obj)
		self.include?(obj)
	end
end

mb.find age: [23, 25, 27]
```

The block is invoked with every item and can do more complex tests.  
Its return value is interpreted as a boolean value:

```ruby
mb.find { |item| item.age - item.child.age > 20 }
```

In addition to the evaluation logic, the arrays returned by all variants of `find` can be merged:

```ruby
mb.find(...) | mb.find(...) | mb.find(...)
```

Note that the pipe operator `|` already eliminates duplicates:

```ruby
[a, b, c] | [c, d, e]
# => [a, b, c, d, e]
# which is equal to
([a, b, c] + [c, d, e]).uniq
```

### Serialization

#### Binary

The data store can easily be serialized and restored in binary format:

```ruby
mb.to_file("datastore.bin")
# => number of bytes written
MemStore.from_file("datastore.bin")
# => instance of ObjectStore or HashStore
```

MemStore will automatically restore the correct class (`ObjectStore`/`HashStore`), key and items.

#### Hash

`HashStore` can be converted to and from a hash:

```ruby
h = mb.to_hash
# => { key: ..., items: { ... } }
MemStore::HashStore.from_hash(h)
# => instance of HashStore
```

#### YAML

`memstore/yaml` enables serialization of `HashStore` to and from [YAML](http://yaml.org/):

```ruby
require "memstore/yaml" # requires "yaml"

mb.to_yaml
# => YAML string
mb.to_yaml_file(file)
# => number of bytes written
MemStore::HashStore.from_yaml(yaml)
# => instance of HashStore
MemStore::HashStore.from_yaml_file(file)
# => instance of HashStore
```

De/serialization is seamless since YAML can handle symbols and non-string keys (i.e. Psych converts them correctly).

#### JSON

`memstore/json` enables serialization of `HashStore` to and from [JSON](http://www.json.org/):

```ruby
require "memstore/json" # requires "json"

mb.to_json
# => JSON string
mb.to_json_file(file)
# => number of bytes written
MemStore::HashStore.from_json(json)
# => instance of HashStore
MemStore::HashStore.from_json_file(file)
# => instance of HashStore
```

**Important:** Symbols will be converted to strings and JSON only allows string keys.

```ruby
mb = MemStore::HashStore.new(:id)
mb << { id: 1 }
mb.to_hash
# => { :key => :id, :items => { 1 => { :id => 1 } } }
mb = MemStore::HashStore.from_json(mb.to_json)
mb.to_hash
# => { :key => "id", :items => { "1" => { "id" => 1 } } }
```

The following style ensures consistent access before and after serialization:

```ruby
mb = MemStore::HashStore.new("id")
mb << { "id" => "1" }
mb["1"]
# => { "id" => "1" }
```

#### MessagePack

`memstore/msgpack` enables serialization of `HashStore` to and from [MessagePack](http://msgpack.org/):

```ruby
require "memstore/msgpack" # requires "msgpack"

mb.to_msgpack
# => MessagePack binary format
mb.to_msgpack_file(file)
# => number of bytes written
MemStore::HashStore.from_msgpack(msgpack)
# => instance of HashStore
MemStore::HashStore.from_msgpack_file(file)
# => instance of HashStore
```

**Important:** Symbols will be converted to strings but non-string keys are allowed.

```ruby
mb = MemStore::HashStore.new(:id)
mb << { id: 1 }
mb.to_hash
# => { :key => :id, :items => { 1 => { :id => 1 } } }
mb = MemStore::HashStore.from_msgpack(mb.to_msgpack)
mb.to_hash
# => { :key => "id", :items => { 1 => { "id" => 1 } } }
```

The following style ensures consistent access before and after serialization:

```ruby
mb = MemStore::HashStore.new("id")
mb << { "id" => 1 }
mb[1]
# => { "id" => 1 }
```

## Contributing

1. Fork it
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create new Pull Request
