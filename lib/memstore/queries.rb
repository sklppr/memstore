# encoding: utf-8

module MemStore

  class ObjectStore

    # Methods for searching and counting items based on conditions.

    # All methods have the following signature:
    #
    # conditions - Hash mapping attributes to conditions.
    #              Attributes can be Symbols or String for ObjectStore
    #              and any kind of Object for HashStore.
    #              Conditions can be any kind of Object that responds to #===.
    # block - Optional block taking an item and returning a bool indicating
    #         whether the item passed the tests within the block.
    #
    # Yields every item in the data store after the conditions were evaluated for it.

    ### find ###

    # Returns an Array of items that fulfill all conditions.
    def find_all(conditions={}, &block)
      all.select { |item| match_all(item, conditions, &block) }
    end
    alias_method :find, :find_all

    # Returns an Array of items that fulfill at least one condition.
    def find_any(conditions={}, &block)
      all.select { |item| match_any(item, conditions, &block) }
    end

    # Returns an Array of items that fulfill exactly one condition.
    def find_one(conditions={}, &block)
      all.select { |item| match_one(item, conditions, &block) }
    end

    # Returns an Array of items that violate at least one condition.
    def find_not_all(conditions={}, &block)
      all.reject { |item| match_all(item, conditions, &block) }
    end

    # Returns an Array of items that violate all conditions.
    def find_none(conditions={}, &block)
      all.select { |item| match_none(item, conditions, &block) }
    end

    ### first ###

    # Returns the first item that fulfills all conditions.
    def first_all(conditions={}, &block)
      all.detect { |item| match_all(item, conditions, &block) }
    end
    alias_method :first, :first_all

    # Returns the first item that fulfills at least one condition.
    def first_any(conditions={}, &block)
      all.detect { |item| match_any(item, conditions, &block) }
    end

    # Returns the first item that fulfills exactly one condition.
    def first_one(conditions={}, &block)
      all.detect { |item| match_one(item, conditions, &block) }
    end

    # Returns the first item that violates at least one condition.
    def first_not_all(conditions={}, &block)
      all.detect { |item| !match_all(item, conditions, &block) }
    end

    # Returns the first item that violates all conditions.
    def first_none(conditions={}, &block)
      all.detect { |item| match_none(item, conditions, &block) }
    end

    ### count ###

    # Returns the number of items that fulfill all conditions.
    def count_all(conditions={}, &block)
      all.count { |item| match_all(item, conditions, &block) }
    end
    alias_method :count, :count_all

    # Returns the number of items that fulfill at least one condition.
    def count_any(conditions={}, &block)
      all.count { |item| match_any(item, conditions, &block) }
    end

    # Returns the number of items that fulfill exactly one condition.
    def count_one(conditions={}, &block)
      all.count { |item| match_one(item, conditions, &block) }
    end

    # Returns the number of items that violate at least one condition.
    def count_not_all(conditions={}, &block)
      all.count { |item| !match_all(item, conditions, &block) }
    end

    # Returns the number of items that violate all conditions.
    def count_none(conditions={}, &block)
      all.count { |item| match_none(item, conditions, &block) }
    end

    ### delete ###

    # Deletes and returns items that fulfill all conditions.
    def delete_all(conditions={}, &block)
      @items.inject([]) do |items, (key, item)|
        items << @items.delete(key) if match_all(item, conditions, &block)
        items
      end
    end
    alias_method :delete, :delete_all

    # Deletes and returns items that fulfill at least one condition.
    def delete_any(conditions={}, &block)
      @items.inject([]) do |items, (key, item)|
        items << @items.delete(key) if match_any(item, conditions, &block)
        items
      end
    end

    # Deletes and returns items that fulfill exactly one condition.
    def delete_one(conditions={}, &block)
      @items.inject([]) do |items, (key, item)|
        items << @items.delete(key) if match_one(item, conditions, &block)
        items
      end
    end

    # Deletes and returns items that violate at least one condition.
    def delete_not_all(conditions={}, &block)
      @items.inject([]) do |items, (key, item)|
        items << @items.delete(key) if !match_all(item, conditions, &block)
        items
      end
    end

    # Deletes and returns items that violate all conditions.
    def delete_none(conditions={}, &block)
      @items.inject([]) do |items, (key, item)|
        items << @items.delete(key) if match_none(item, conditions, &block)
        items
      end
    end

    private
    
    # All methods have the following signature:
    #
    # item - The item (Object for ObjectStore, Hash for HashStore) to be tested.
    # conditions - Hash of conditions to be evaluated.
    # block - Optional block that can test the item after the conditions are evaluated.
    #
    # Returns a bool indicating whether the item passed the conditions and matching logic.

    # Internal: Evaluates conditions using AND, i.e. condition && condition && ... [&& block]
    def match_all(item, conditions={})
      conditions.all? { |attribute, condition| condition === attr(item, attribute) } &&
        if block_given? then yield(item) else true end
    end
  
    # Internal: Evaluates conditions using OR, i.e. condition || condition || ... [|| block]
    def match_any(item, conditions={})
      conditions.any? { |attribute, condition| condition === attr(item, attribute) } ||
        if block_given? then yield(item) else false end
    end

    # Internal: Evaluates conditions using XOR, i.e. condition ^ condition ^ condition ... [^ block]
    def match_one(item, conditions={})
      conditions.one? { |attribute, condition| condition === attr(item, attribute) } ^
        if block_given? then yield(item) else false end
    end

    # Internal: Evaluates condition using AND NOT, i.e. !condition && !condition && ... [&& !block]
    def match_none(item, conditions={})
      conditions.none? { |attribute, condition| condition === attr(item, attribute) } &&
        if block_given? then !yield(item) else true end
    end

  end
  
end
