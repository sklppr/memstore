class MemStore

  # Initializes an MemStore.
  #
  # key    - optional String/Symbol to be sent or Proc/lambda/method to be called
  # access - optional String/Symbol to be sent or Proc/lambda/method to be called
  # items  - optional Array of items to be added
  #
  # Returns initialized MemStore.
  def initialize(key: nil, access: nil, items: nil)

    @items = {}

    define_singleton_method :access_key,
      if key.nil?
        -> item { item.hash }
      elsif key.respond_to?(:call)
        -> item { key.call(item) }
      else
        -> item { access_attribute(item, key) }
      end

    define_singleton_method :access_attribute,
      if access.nil?
        -> item, attribute { item.send(attribute) }
      elsif [Symbol, String].include?(access.class)
        -> item, attribute { item.send(access, attribute) }
      elsif access.respond_to?(:call)
        -> item, attribute { access.call(item, attribute) }
      else
        raise "No usable access method."
      end
    
    add(*items) unless items.nil?

  end

  # Provides access to internal items collection (which is simply a Hash).
  attr_accessor :items

  # Returns all items as an Array.
  def all
    @items.values
  end

  # Returns total number of items in the data store.
  def size
    @items.length
  end

  # Adds one item to the data store.
  #
  # item - item to add
  #
  # Returns the data store itself.
  #
  # Raises NoMethodError when an item does’t respond to the key attribute method.
  def <<(item)
    @items[access_key(item)] = item
    self
  end

  # Adds one or more items to the data store.
  #
  # items - items to be added
  #
  # Returns the data store itself.
  #
  # Raises NoMethodError when an item does’t respond to the key attribute method.
  def add(*items)
    items.each { |item| self << item }
    self
  end

  # Retrieves one item by key.
  #
  # key - key of item to be retrieved
  #
  # Returns item if it exists, otherwise nil.
  def [](key)
    @items[key]
  end

  # Retrieves one or more items by key.
  #
  # keys - keys of items to be retrieved
  #
  # Returns an array of items with nil where no item with that key exists.
  def get(*keys)
    keys.collect { |key| @items[key] }
  end

  # Deletes one item by reference.
  #
  # item - item to be deleted
  #
  # Returns the item that was deleted or nil if it doesn’t exist.
  def delete_item(item)
    @items.delete(access_key(item))
  end

  # Deletes one or more items by reference.
  #
  # items - items to be deleted
  #
  # Returns an array of items that were deleted with nil where an item doesn’t exist.
  def delete_items(*items)
    items.collect { |item| @items.delete(access_key(item)) }
  end

  # Deletes one item by key.
  #
  # key - key of item to be deleted
  #
  # Returns the item that was deleted or nil if it doesn’t exist.
  def delete_key(key)
    @items.delete(key)
  end

  # Deletes one or more items by key.
  #
  # keys - keys of items to be deleted
  #
  # Returns an array of items that were deleted with nil where no item with that key exists.
  def delete_keys(*keys)
    keys.collect { |key| @items.delete(key) }
  end

  # Collects values of given attribute from all items.
  #
  # attribute - name of attribute to be collected (symbol or string)
  #
  # Returns an array of attribute values of each item.
  def collect(attribute)
    all.collect { |item| access_attribute(item, attribute) }
  end

end
