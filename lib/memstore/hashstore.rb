# encoding: utf-8

module MemStore

  class HashStore < ObjectStore

    # HashStore accesses item attributes through item[attribute].

    # Initializes a HashStore.
    #
    # key   - Optional Object used as an item’s key attribute (default: nil).
    #         When no key is specified, Object#hash will be used for uniquely identifying items.
    # items - Optional Hash of items to initialize the data store with (default: empty Hash).
    #
    # Examples
    #
    #   store = HashStore.new
    #   store = HashStore.new(:id)
    #   store = HashStore.new(nil, { a.hash => a, b.hash => b, c.hash => c })
    #   store = HashStore.new(:id, { 1 => a, 2 => b, 3 => c })
    #
    # Returns initialized ObjectStore.
    def initialize(key=nil, items={})
      @key, @items = key, items
    end

    private

    # Internal: Obtains the key attribute of an item.
    #
    # item - Object that responds to the [] operator (e.g. Hash).
    #
    # Returns result of calling the [] operator with the key attribute on the item.
    #
    # Raises NoMethodError when item does’t respond to the key attribute method.
    def key(item)
      if @key.nil? then item.hash else item[@key] end
    end

    # Internal: Obtains the specified attribute of an item.
    #
    # item - Object that responds to the [] operator (e.g. Hash).
    # attribute - Object used as the attribute key in the item.
    #
    # Returns result of calling the [] operator with the attribute on the item.
    #
    # Raises NoMethodError when item does’t respond to the [] operator.
    def attr(item, attribute)
      item[attribute]
    end

  end

end
