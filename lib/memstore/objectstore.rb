# encoding: utf-8

module MemStore

  # An ObjectStore accesses item attributes through item#attribute.
  class ObjectStore

    # Initializes an ObjectStore.
    #
    # key   - Optional Symbol or String naming the method to obtain an item’s key attribute (default: nil).
    #         When no key is specified, Object#hash will be used for uniquely identifying items.
    # items - Optional Hash of items to initialize the data store with (default: empty Hash).
    #
    # Examples
    #
    #   store = ObjectStore.new
    #   store = ObjectStore.new(:id)
    #   store = ObjectStore.new(nil, { a.hash => a, b.hash => b, c.hash => c })
    #   store = ObjectStore.new(:id, { 1 => a, 2 => b, 3 => c })
    #
    # Returns initialized ObjectStore.
    def initialize(key=nil, items={})
      @key = key || :hash
      @items = items
    end

    # Provides access to internal items collection (which is simply a Hash).
    attr_accessor :items

    # Inserts one or more items into the data store, can be chained.
    # Also available as #<<, which only allows for one item at a time.
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
    # Raises NoMethodError when an item does’t respond to the key attribute method.
    def insert(*items)
      items.each { |item| @items[key(item)] = item }
      self
    end
    alias_method :<<, :insert
    
    # Returns total number of items in the data store. Also available as #size.
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
    # Returns an Object if a single key was given
    #   or nil if no item with that key exists
    #   or an Array of Objects when multiple keys were given
    #   in which nil is placed wherever there isn’t an item with that key.
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

    # Deletes one or more items by reference. Also available as #delete_item and #delete.
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
    # Returns the Object that was removed if a single item was given
    #   or nil if the item isn’t in the data store
    #   or an Array of Objects that were removed when multiple items were given
    #   in which nil is placed wherever that item isn’t in the data store.
    def delete_items(*items)
      return @items.delete(key(items.first)) if items.length == 1
      items.collect { |item| @items.delete(key(item)) }
    end
    alias_method :delete_item, :delete_items
    alias_method :delete, :delete_items

    # Deletes one or more items by key. Also available as #delete_key.
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
    # Returns the Object that was removed if a single key was given
    #   or nil if no item with that key exists
    #   or an Array of Objects that were removed when multiple keys were given
    #   in which nil is placed wherever there isn’t an item with that key.
    def delete_keys(*keys)
      return @items.delete(keys.first) if keys.length == 1 && !keys.first.is_a?(Range)
      keys.inject([]) do |items, key|
        if key.is_a?(Range) then key.inject(items) { |i, k| i << @items.delete(k) }
        else items << @items.delete(key) end
      end
    end
    alias_method :delete_key, :delete_keys

    # Returns data store in binary format.
    # Raises whatever Marshal::dump raises.
    def to_binary
      Marshal.dump(self)
    end

    # Writes data store to a file in binary format.
    #
    # file - IO stream of file name as String.
    #
    # Returns number of bytes that were written to the file.
    # Raises whatever IO::write raises.
    def to_file(file)
      IO.write(file, self.to_binary)
    end

    # Restores a data store from binary format.
    #
    # binary - Binary data containing a serialized instance of ObjectStore.
    #
    # Examples
    #
    #   store = ObjectStore.from_binary(IO.read(file))
    #
    # Returns instance of ObjectStore
    #   or nil if marshalling failed or marshalled object isn’t an ObjectStore.
    # Raises whatever Marshal::load raises.
    def self.from_binary(binary)
      restored = Marshal.load(binary) rescue nil
      if restored.instance_of?(ObjectStore) then restored else nil end
    end

    # Restores a data store from a binary file.
    #
    # file - IO stream or file name as String.
    #
    # Examples
    #
    #   store = ObjectStore.from_file(file)
    #
    # Returns instance of ObjectStore or nil (result of ::from_binary)
    #   or nil if file IO failed, e.g. because file doesn’t exist or isn’t readable.
    # Raises whatever IO::read or Marshal::load raise.
    def self.from_file(file)
      self.from_binary(IO.read(file)) rescue nil
    end

    # Executes a given block while keeping an exclusive lock on a file.
    # Allows to use the same file for persistence from multiple threads/processes.
    # Tries to deserialize a data store from the file using ::from_file.
    # If that fails, a new one will be created using the supplied key and items.
    # Writes data store back to file using #to_file after block returns.
    #
    # file - IO stream or file name as String.
    # key - Optional key attribute (Symbol or String) to use in ::new (default: nil).
    # items - Optional items Hash to use in ::new (default: empty Hash).
    # block - Block that will be called after a data store was restored or created.
    #
    # Yields the restored or newly created data store.
    #
    # Examples
    #
    #   size_after_changes = ObjectStore.with_file(file, :id) do |store|
    #     store.delete(a, b, c, d, e)
    #     store.insert(f, g, h)
    #     store.size
    #   end
    # 
    # Returns whatever the block returns.
    # Raises whatever File::open, IO::read, Marshal::load, Marshal::dump or IO::write raise.
    def self.with_file(file, key=nil, items={}, &block)
      self.execute_with_file(:from_file, :to_file, file, key, items, &block)
    end

    private

    # Internal: Obtains the key attribute of an item.
    #
    # item - Object that responds to the attribute.
    #
    # Returns result of calling the key attribute method on the item.
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
    # Raises NoMethodError when item does’t respond to the attribute method.
    def attr(item, attribute)
      item.send(attribute)
    end

    # Internal: Used to implement with_file and variants for different formats/subclasses.
    # Takes required method names, can therefore be used by any subclass.
    # Executes a given block while keeping an exclusive lock on a file.
    # Tries to deserialize a data store from the file using from_file_method.
    # If that fails, a new one will be created using the supplied key and items.
    # Writes data store back to file using to_file_method after block returns.
    #
    # from_file_method - Name of class method (Symbol or String) to deserialize data store from file.
    # to_file_method - Name of instance method (Symbol or String) to serialize data store to file.
    # file - IO stream or file name as String.
    # key - Optional key attribute (Symbol or String) to use in ::new (default: nil).
    # items - Optional items Hash to use in ::new (default: empty Hash).
    # block - Block that will be called after a data store was restored or created.
    #
    # Yields the restored or newly created data store.
    # 
    # Returns whatever the block returns.
    # Raises whatever File::open, IO::read, Marshal::load, Marshal::dump or IO::write raise.
    def self.execute_with_file(from_file_method, to_file_method, file, key=nil, items={}, &block)
      File.open(file) do |file|
        file.flock(File::LOCK_EX)
        store = self.send(from_file_method, file) || self.new(key, items)
        result = block.call(store)
        store.send(to_file_method, file)
        file.flock(File::LOCK_UN)
        result
      end
    end

  end
  
end
