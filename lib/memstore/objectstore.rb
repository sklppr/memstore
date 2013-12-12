# encoding: utf-8

module MemStore

  class ObjectStore

    # ObjectStore accesses item attributes through item#attribute.

    # Initializes an ObjectStore.
    #
    # key   - Optional Symbol or String naming the method to obtain an item’s key attribute (default: nil).
    #         When no key is specified, Object#hash will be used for uniquely identifying items.
    #
    # Examples
    #
    #   store = ObjectStore.new
    #   store = ObjectStore.new(:id)
    #
    # Returns initialized ObjectStore.
    def initialize(key=nil)
      @key = key || :hash
      @items = {}
    end

    # Provides access to internal items collection (which is simply a Hash).
    attr_accessor :items

    # Inserts one or more items into the data store, can be chained.
    # The aliased shovel operator #<< only allows adding one item at a time.
    #
    # items - One or more Objects that respond to the method specified as key attribute.
    #
    # Examples
    #
    #   store.insert(a).insert(b).insert(c)
    #   store.insert(a, b, c)
    #   store << a << b << c
    #
    # Returns the data store itself to enable chaining.
    #
    # Raises NoMethodError when an item does’t respond to the key attribute method.
    def insert(*items)
      items.each { |item| @items[key(item)] = item }
      self
    end
    alias_method :<<, :insert
    
    # Returns total number of items in the data store.
    def length
      @items.length
    end
    alias_method :size, :length

    # Retrieves one or more items by key.
    #
    # keys - One or more Objects or Ranges that are keys of items.
    #        For a Range, all items with keys in that range are returned.
    #
    # Examples
    #
    #   store[1]
    #   store[1, 2, 3]
    #   store[1..3]
    #   store[1, 3..5, 7]
    #
    # Returns an Object if a single key was given and the item was found
    #   or nil if a single key was given and no item with that key exists
    #   or an Array if multiple keys were given, with nil where no item with that key exists
    def [](*keys)
      return @items[keys.first] if keys.length == 1 && !keys.first.is_a?(Range)
      keys.inject([]) do |items, key|
        if key.is_a?(Range) then key.inject(items) { |i, k| i << @items[k] }
        else items << @items[key] end
      end
    end

    # Returns all items as an Array.
    def all
      @items.values
    end

    # Deletes one or more items by reference.
    #
    # items - One or more Objects that respond to the method specified as key attribute.
    #
    # Examples
    #
    #   store.delete_item(a)
    #   store.delete_items(a, b, c)
    #   store.delete(a)
    #   store.delete(a, b, c)
    #
    # Returns the Object that was removed if a single item was given and found
    #   or nil if a single item was given and not found
    #   or an Array if multiple keys were given, with nil where an item wasn’t found.
    def delete_items(*items)
      return @items.delete(key(items.first)) if items.length == 1
      items.collect { |item| @items.delete(key(item)) }
    end
    alias_method :delete_item, :delete_items
    alias_method :delete, :delete_items

    # Deletes one or more items by key.
    #
    # keys - One or more Objects or Ranges that are keys of items.
    #        For a Range, all items with keys in that range are deleted.
    #
    # Examples
    #
    #   store.delete_key(1)
    #   store.delete_keys(1, 2, 3)
    #   store.delete_keys(1..3)
    #   store.delete_keys(1, 3..5, 7)
    #
    # Returns the Object that was removed if a single key was given and the item was found
    #   or nil if a single key was given and no item with that key exists
    #   or an Array if multiple keys were given, with nil where no item with that key exists.
    def delete_keys(*keys)
      return @items.delete(keys.first) if keys.length == 1 && !keys.first.is_a?(Range)
      keys.inject([]) do |items, key|
        if key.is_a?(Range) then key.inject(items) { |i, k| i << @items.delete(k) }
        else items << @items.delete(key) end
      end
    end
    alias_method :delete_key, :delete_keys

    private

    # Internal: Obtains the key attribute of an item.
    #
    # item - Object that responds to the attribute.
    #
    # Returns result of calling the key attribute method on the item.
    #
    # Raises NoMethodError when item does’t respond to the key attribute method.
    def key(item)
      item.send(@key)
    end

    # Internal: Obtains the specified attribute of an item.
    #
    # item - Object that responds to the attribute.
    # attribute - Symbol or String naming the attribute.
    #
    # Returns result of calling the attribute method on the item.
    #
    # Raises NoMethodError when item does’t respond to the attribute method.
    def attr(item, attribute)
      item.send(attribute)
    end

  end
  
end
