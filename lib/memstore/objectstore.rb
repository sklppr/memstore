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
    def add(*items)
      items.each { |item| @items[key(item)] = item }
      self
    end
    alias_method :<<, :add
    
    # Returns total number of items in the data store.
    def size
      @items.length
    end

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
    def get(*keys)
      return @items[keys.first] if keys.length == 1 && !keys.first.is_a?(Range)
      keys.inject([]) do |items, key|
        if key.is_a?(Range) then key.inject(items) { |i, k| i << @items[k] }
        else items << @items[key] end
      end
    end
    alias_method :[], :get

    # Returns all items as an Array.
    def all
      @items.values
    end

    # Deletes one item by reference.
    #
    # item - Object that responds to the method specified as key attribute.
    #
    # Examples
    #
    #   store.delete_item(a)
    #
    # Return the Object that was deleted from the data store
    #   or nil if the item didn’t exist in the data store.
    def delete_item(item)
      @items.delete(key(item))
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
    # Returns an Array of Objects that were deleted from the data store
    #   with nil where an item didn’t exist in the data store.
    def delete_items(*items)
      items.collect { |item| @items.delete(key(item)) }
    end

    # Deletes one item by key.
    #
    # key - Object that is key of an item.
    #
    # Examples
    #
    #   store.delete_key(1)
    #
    # Return the Object that was deleted from the data store
    #   or nil if the item didn’t exist in the data store.
    def delete_key(key)
      @items.delete(key)
    end

    # Deletes one or more items by key.
    #
    # keys - One or more Objects or Ranges that are keys of items.
    #        For a Range, all items with keys in that range are deleted.
    #
    # Examples
    #
    #   store.delete_keys(1, 2, 3)
    #
    # Returns an Array of Objects that were deleted from the data store
    #   with nil where an item didn’t exist in the data store.
    def delete_keys(*keys)
      keys.collect { |key| @items.delete(key) }
    end

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
