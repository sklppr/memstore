class MemStore

  # Initializes an MemStore.
  #
  # key    - Mechanism to determine the identity of an item.
  #          Optional, default is Object#hash.
  #          Can be a String/Symbol to be sent or a Proc/lambda/method to be called.
  # type   - Mechanism to determine the type of an item.
  #          Optional, default is Object#class.
  #          Can be a String/Symbol to be sent or a Proc/lambda/method to be called.
  # access - Mechanism to access attributes of an item.
  #          Optional, default is Object#send.
  #          Can be a String/Symbol to be sent or a Proc/lambda/method to be called.
  # items  - Array of items to be added initially (optional).
  #
  # Returns initialized MemStore.
  def initialize(key: nil, type: nil, access: nil, items: nil)

    # Create hash to index all items by key.
    @items = {}

    # Dynamically define method to access an item's attributes.
    define_singleton_method :access_attribute,
      if access.nil?
        -> item, attribute { item.respond_to?(attribute) ? item.send(attribute) : nil }
      elsif [Symbol, String].include?(access.class)
        -> item, attribute { item.send(access, attribute) }
      elsif access.respond_to?(:call)
        -> item, attribute { access.call(item, attribute) }
      else
        raise "No usable access method."
      end

    # Dynamically define method to access an item's key.
    define_singleton_method :access_key,
      if key.nil?
        -> item { item.hash }
      elsif key.respond_to?(:call)
        -> item { key.call(item) }
      else
        -> item { access_attribute(item, key) }
      end

    # Dynamically define method to access an item's type.
    define_singleton_method :access_type,
      if type.nil?
        -> item { item.class }
      elsif type.respond_to?(:call)
        -> item { type.call(item) }
      else
        -> item { access_attribute(item, type) }
      end
    
    add(*items) unless items.nil?

  end

  # Provides access to all items as a hash, optionally restricted by type.
  # Raises NoMethodError when an item doesn't respond to the type attribute method.
  def items(type=nil)
    return @items if type.nil?
    @items.select { |key, item| match_type?(item, type) }
  end

  # Allows to set the items hash directly.
  def items=(hash)
    @items = hash
  end

  # Returns all items as an array, optionally restricted by type.
  # Raises NoMethodError when an item doesn't respond to the type attribute method.
  def all(type=nil)
    return @items.values if type.nil?
    @items.values.select { |item| match_type?(item, type) }
  end

  # Returns total number of items in the data store, optionally restricted by type.
  # Raises NoMethodError when an item doesn't respond to the type attribute method.
  def size(type=nil)
    return @items.length if type.nil?
    @items.select { |key, item| match_type?(item, type) }.length
  end

  # Adds one item to the data store.
  #
  # item - item to add
  #
  # Returns the data store itself.
  #
  # Raises NoMethodError when an item doesn't respond to the key attribute method.
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
  # Raises NoMethodError when an item doesn't respond to the key attribute method.
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
    keys.collect { |key| self[key] }
  end

  # Deletes one item by reference.
  #
  # item - item to be deleted
  #
  # Returns the item that was deleted or nil if it doesn't exist.
  def delete_item(item)
    @items.delete(access_key(item))
  end

  # Deletes one or more items by reference.
  #
  # items - items to be deleted
  #
  # Returns an array of items that were deleted with nil where an item doesn't exist.
  def delete_items(*items)
    items.collect { |item| @items.delete(access_key(item)) }
  end

  # Deletes one item by key.
  #
  # key - key of item to be deleted
  #
  # Returns the item that was deleted or nil if it doesn't exist.
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
  
  private
  
  # Evaluates if given item matches one or move given types.
  # 
  # item - item to evaluate
  # type - single type or array of types to allow
  # 
  # Returns boolean indicating type match.
  def match_type?(item, type)
    [type].flatten.include?(access_type(item))
  end

end
