# encoding: utf-8

module MemStore

  class ObjectStore

    def initialize(key=nil, items={})
      @key = key || :hash
      @items = items
    end

    attr_accessor :items

    def insert(*items)
      items.each { |item| @items[key(item)] = item }
      self
    end
    alias_method :<<, :insert
    
    def length
      @items.length
    end
    alias_method :size, :length
    alias_method :count, :length

    def [](*keys)
      return @items[keys.first] if keys.length == 1 && !keys.first.is_a?(Range)
      keys.inject [] do |items, key|
        if key.is_a?(Range) then key.inject(items) { |i, k| i << @items[k] }
        else items << @items[key] end
      end
    end

    def all
      @items.values
    end

    def delete_items(*items)
      return @items.delete(key(items.first)) if items.length == 1
      items.collect { |item| @items.delete(key(item)) }
    end
    alias_method :delete_item, :delete_items
    alias_method :delete, :delete_items

    def delete_keys(*keys)
      return @items.delete(keys.first) if keys.length == 1 && !keys.first.is_a?(Range)
      keys.inject [] do |items, key|
        if key.is_a?(Range) then key.inject(items) { |i, k| i << @items.delete(k) }
        else items << @items.delete(key) end
      end
    end
    alias_method :delete_key, :delete_keys

    def self.from_binary(binary)
      restored = Marshal.load(binary) rescue nil
      if restored.kind_of?(ObjectStore) || restored.kind_of?(HashStore) then restored else nil end
    end

    def self.from_file(file)
      self.from_binary(IO.read(file)) rescue nil
    end

    def to_binary
      Marshal.dump(self)
    end

    def to_file(file)
      IO.write(file, self.to_binary)
    end

    def self.with_file(file, key=nil, items={}, &block)
      self.run_with_file(:from_file, :to_file, file, key, items, &block)
    end

    private

    def key(item)
      item.send(@key)
    end

    def attr(item, attribute)
      item.send(attribute)
    end

    def self.run_with_file(from_file_method, to_file_method, file, key=nil, items={}, &block)
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
