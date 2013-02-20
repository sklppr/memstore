require "memstore/version"

module MemStore

  def self.new(key=nil, items={})
    ObjectStore.new(key, items)
  end

  def self.from_binary(binary)
    begin Marshal.load(binary) rescue nil end
  end

  def self.from_file(file)
    begin self.from_binary(IO.read(file)) rescue nil end
  end

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
    
    def size
      @items.length
    end

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
  
    def find_all(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end
    alias_method :find, :find_all

    def find_any(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_ANY) }
    end

    def find_one(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_ONE) }
    end

    def find_not_all(conditions={}, &block)
      all.reject { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end

    def find_none(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_NONE) }
    end

    def first_all(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end
    alias_method :first, :first_all

    def first_any(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_ANY) }
    end

    def first_one(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_ONE) }
    end

    def first_not_all(conditions={}, &block)
      all.detect { |item| !instance_exec(item, conditions, block, &FIND_ALL) }
    end

    def first_none(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_NONE) }
    end

    def to_binary
      Marshal.dump(self)
    end

    def to_file(file)
      IO.write(file, self.to_binary)
    end

    private
  
    FIND_ALL = Proc.new do |item, conditions, block|
        conditions.all? { |attribute, condition| condition === attr(item, attribute) } &&
          if block then !!block.call(item) else true end
      end
  
    FIND_ANY = Proc.new do |item, conditions, block|
        conditions.any? { |attribute, condition| condition === attr(item, attribute) } ||
          if block then !!block.call(item) else false end
      end

    FIND_NONE = Proc.new do |item, conditions, block|
        conditions.none? { |attribute, condition| condition === attr(item, attribute) } &&
          if block then !!block.call(item) else true end
      end

    FIND_ONE = Proc.new do |item, conditions, block|
        conditions.one? { |attribute, condition| condition === attr(item, attribute) } ||
          if block then !!block.call(item) else false end
      end

    def key(item)
      item.send(@key)
    end

    def attr(item, attribute)
      item.send(attribute)
    end

  end

  class HashStore < ObjectStore

    def self.from_hash(hash)
      begin
        key = hash[:key] || hash["key"]
        items = hash[:items] || hash["items"]
        return nil if key.nil? || items.nil?
        self.new(key, items)
      rescue
        nil
      end
    end

    def initialize(key=nil, items={})
      @key, @items = key, items
    end

    def to_hash
      { key: @key, items: @items }
    end

    private

    def key(item)
      if @key.nil? then item.hash else item[@key] end
    end

    def attr(item, attribute)
      item[attribute]
    end

  end

end
