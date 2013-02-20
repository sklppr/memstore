# encoding: utf-8

module MemStore

  class HashStore < ObjectStore

    def self.from_hash(hash)
      begin

        if hash.has_key?(:key) then key = hash[:key]
        elsif hash.has_key? "key" then key = hash["key"]
        else return nil end

        if hash.has_key?(:items) then items = hash[:items]
        elsif hash.has_key? "items" then items = hash["items"]
        else return nil end

        if items.is_a?(Hash) then self.new(key, items) else self.new(key) end

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
