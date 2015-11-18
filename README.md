# MemStore

*A simple in-memory data store.*

MemStore is a simple in-memory data store that supports complex search queries. It’s not in any way supposed to be a database. However, it can be used instead of database in small applications or prototypes.

The philosophy behind MemStore is that pure Ruby already gives you several advanced features like complex query logic, finding/counting/deleting items, set operations, map/reduce operations, type differentiation, lazy enumeration and serialization.

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

### Set Operations

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

## Collection Operations

Sometimes you want to work with items in the store, for example to run map/reduce operations. MemStore provides direct access to its items in both hash and array form. Additionally, it offers a shortcut to collect all values of a certain attribute using the specified attribute access method.

### Item Enumeration

You can directly access `store.items` or `store.all` and apply all respective enumeration methods.

```ruby
store.all.map { |item| "#{item.name} (#{item.age})" }
# => ["Peter (23)", "Paul (42)", "Mary (33)"]
store.all.reduce(0) { |sum, item| sum + item.age }
# => 98
```

### Attribute Collection

MemStore provides a shortcut to collect attribute values from all items. The result is an array and could also be used for map/reduce operations.

```ruby
store.collect(:age)
# => [23, 42, 33]
store.collect(:age).reduce(:+)
# => 98
```

This shortcut automatically uses the correct access method for attributes (see [Customization](#customization)).

## Item Types

MemStore is able to deal with items of different types. By default, all items in the store are used for queries. However, you can use the type parameter to restrict 

By default, MemStore uses `item.class` to identify its type, but you can specify another attribute to be used when instantiating a store or even use a custom access method (see [Customization](#customization)).

```ruby
store = MemStore.new(type: :type)
# uses item.type to determine type
store = MemStore.new(access: :[], type: :type)
# uses item[:type] to determine type
```

### Type Restriction

MemStore is able to restrict access and queries based on item type. The access methods `items`, `all` and `size` as well as all query methods (`find_*`, `lazy_find_*`, `first_*`, `count_*`, `delete_*`) optionally take a type identifier as their first parameter.

```ruby
store.items(Person)
# returns hash of all items of that type
store.all(Person)
# returns array of all items of that type
store.size(Person)
# returns number of all items of that type
store.find(Person, age: 25..35)
# returns all items of that type fulfilling the conditions
store.lazy_find(Person, age: 25..35)
# returns lazy enumerator to find items of that type fulfilling the conditions
store.first(Person, age: 25..35)
# returns first item of that type fulfilling the conditions
store.count(Person, age: 25..35)
# returns count of items of that type fulfilling the conditions
store.delete(Person, age: 25..35)
# deletes and returns array of items of that type fulfilling the conditions
```

If a type is provided, the result will be restricted to only items of that type. In case of queries this filter is applied before evaluating conditions and is not affected by the query logic. See [Customization](#customization) for how to provide your own type attribute instead of using the item’s class.

### Nonexistent Attributes

When items don’t have a certain attribute, it is interpreted as `nil`. For hashes this is true by default and in the standard configuration MemStore also uses `nil` when objects don’t respond to an attribute accessor. You can override this behavior by defining your own attribute access method (see [Customization](#customization)).

Primarily, you have to keep this in mind when constructing queries: `nil` will probably not fulfill any conditions so negated query logic will include types that don’t even have the queried attributes. To avoid this, explicitly restrict queries to the desired types.

```ruby
store.find_none(age: 0..25, name: Paul)
# result also includes items that don't even have an age or name
store.find_none(Person, age: 0..25, name: Paul)
# result only includes Person items that fulfill the query
```

You might also have to clean up the results of `collect`.

```ruby
store.collect(:age).reject(&:nil?)
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

When you use `find_*`, `lazy_find_*`, `first_*`, `count_*` or `delete_*`, MemStore calls attributes as methods on your items using `Object#send`. This also means that it doesn’t make a difference whether you use strings or symbols in the conditions hash.

```ruby
store.find(age: 42, name: "John")
store.find("age" => 42, "name" => "John")
# both call item.age and item.name to retrieve attributes
```

Type is determined using `Object#class` so you can easily restrict your queries when working with your own entity classes. Note that type comparison uses `==` so subclasses will not be matched, effectively `instance_of?` and not `kind_of?`.

```ruby
store.all(MyClass)
# calls item.class to determine type
```

### Custom Key Accessor

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

### Custom Type Accessor

You can also use a custom property to differentiate item types.  
To override the default way of using the item’s class, provide `type` parameter when creating a store:

```ruby
store = MemStore.new(type: :type)
store.all(MyClass)
# calls item.type to determine type
```

### Custom Attribute Accessor

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

### Advanced Custom Access

If you want to do something special to obtain an attribute, key or type, you can provide a lambda, proc or method. It will be passed both the item in question and the attribute, key or type to be retrieved and is expected to return the appropriate value.

#### Attributes

You can provide a custom lambda/proc/method to be invoked when attributes of an item need to be accessed. It will be called with the item and attribute name to be fetched.

```ruby
# Lambda:
store = MemStore.new(access: -> item, attribute { item[attribute] })

# Proc:
store = MemStore.new(access: Proc.new { |item, attribute| item.attribute })

# Method:
def item_attribute(item, attribute)
  item.special_accessor(attribute)
end
store = MemStore.new(access: method(:item_attribute))
```

#### Key

Likewise, you can provide a lambda/proc/method to be called when accessing keys. It will be passed the item for which MemStore needs a key and is expected to return a truly unique identifier for that item.

```ruby
# Lambda:
store = MemStore.new(key: -> item { item[:special_identifier] })

# Proc:
store = MemStore.new(key: Proc.new { |item| item.special_identifier })

# Method:
def item_key(item)
 item.special_identifier
end
store = MemStore.new(key: method(:item_key))
```

This is also a way to use a different access method for keys than for other attributes. For example, you might want to use a method `get` to access attributes but a different method `id` should be used to obtain keys.

```ruby
store = MemStore.new(access: :get, key: Proc.new(&:id))
store << item
# calls item.id to retrieve key
store.find(age: 42, name: "John")
# calls item.get(:age) and item.get(:name) to retrieve attributes
```

#### Type

Similar to key access, you can provide a lambda/proc/method that determines the type of an item. It will be called with the item and is expected to return a type identifier.

```ruby
# Lambda:
store = MemStore.new(type: -> item { item[:special_type] })

# Proc:
store = MemStore.new(type: Proc.new { |item| item.special_type })

# Method:
def item_type(item)
 item.special_type
end
store = MemStore.new(key: method(:item_type))
```

This is also a way to use a different access method for type than for other attributes, similar to using a separate access method for keys.

```ruby
store = MemStore.new(access: :get, type: Proc.new(&:type))
store.all(MyClass)
# calls item.type to determine type
store.find(age: 42, name: "John")
# calls item.get(:age) and item.get(:name) to retrieve attributes
```
