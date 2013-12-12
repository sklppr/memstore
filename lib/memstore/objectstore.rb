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
    #   # => store
    #   store = ObjectStore.new(:id)
    #   # => store
    #
    # Returns initialized ObjectStore.
    def initialize(key=nil)
      @key = key || :hash
      @items = {}
    end

    # Provides access to internal items collection (which is simply a Hash).
    attr_accessor :items

    # Adds one item to the data store.
    #
    # item - Object to add.
    #
    # Examples
    #
    #   store << a
    #   # => store
    #
    # Returns the data store itself.
    #
    # Raises NoMethodError when an item does’t respond to the key attribute method.
    def <<(item)
      @items[key(item)] = item
      self
    end

    # Adds one or more items to the data store.
    #
    # items - One or more Objects that respond to the method specified as key attribute.
    #
    # Examples
    #
    #   store.add(a)
    #   # => store
    #   store.add(a, b, c)
    #   # => store
    #
    # Returns the data store itself.
    #
    # Raises NoMethodError when an item does’t respond to the key attribute method.
    def add(*items)
      items.each { |item| self << item }
      self
    end
    
    # Returns total number of items in the data store.
    def size
      @items.length
    end

    # Retrieves one item by key.
    #
    # key - Object that is key of an item.
    #
    # Examples
    #
    #  store[1]
    #  # => a
    #
    # Returns item if it exists, otherwise nil.
    def [](key)
      @items[key]
    end

    # Retrieves one or more items by key.
    #
    # keys - One or more Objects that are keys of items.
    #
    # Examples
    #
    #   store.get(1, 2, 3)
    #   # => [a, b, c]
    #
    # Returns an Array of items with nil where no item with that key exists.
    def get(*keys)
      keys.collect { |key| @items[key] }
    end

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
    #   # => a
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
    #   store.delete_items(a, b, c)
    #   # => [a, b, c]
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
    #   # => a
    #
    # Return the Object that was deleted from the data store
    #   or nil if the item didn’t exist in the data store.
    def delete_key(key)
      @items.delete(key)
    end

    # Deletes one or more items by key.
    #
    # keys - One or more Objects that are keys of items.
    #
    # Examples
    #
    #   store.delete_keys(1, 2, 3)
    #   # => [a, b, c]
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
