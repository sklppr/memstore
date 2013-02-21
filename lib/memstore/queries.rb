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
      all.select { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end
    alias_method :find, :find_all

    # Returns an Array of items that fulfill at least one condition.
    def find_any(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_ANY) }
    end

    # Returns an Array of items that fulfill exactly one condition.
    def find_one(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_ONE) }
    end

    # Returns an Array of items that violate at least one condition.
    def find_not_all(conditions={}, &block)
      all.reject { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end

    # Returns an Array of items that violate all conditions.
    def find_none(conditions={}, &block)
      all.select { |item| instance_exec(item, conditions, block, &FIND_NONE) }
    end

    ### first ###

    # Returns the first item that fulfills all conditions.
    def first_all(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end
    alias_method :first, :first_all

    # Returns the first item that fulfills at least one condition.
    def first_any(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_ANY) }
    end

    # Returns the first item that fulfills exactly one condition.
    def first_one(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_ONE) }
    end

    # which is equivalent to: !condition || !condition || ... [|| !block]
    # Returns the first item that violates at least one condition.
    def first_not_all(conditions={}, &block)
      all.detect { |item| !instance_exec(item, conditions, block, &FIND_ALL) }
    end

    # Returns the first item that violates all conditions.
    def first_none(conditions={}, &block)
      all.detect { |item| instance_exec(item, conditions, block, &FIND_NONE) }
    end

    ### count ###

    # Returns the number of items that fulfill all conditions.
    def count_all(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end
    alias_method :count, :count_all

    # Returns the number of items that fulfill at least one condition.
    def count_any(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_ANY) }
    end

    # Returns the number of items that fulfill exactly one condition.
    def count_one(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_ONE) }
    end

    # which is equivalent to: !condition || !condition || ... [|| !block]
    # Returns the number of items that violate at least one condition.
    def count_not_all(conditions={}, &block)
      all.count { |item| !instance_exec(item, conditions, block, &FIND_ALL) }
    end

    # Returns the number of items that violate all conditions.
    def count_none(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_NONE) }
    end

    private
    
    # All blocks have the following signature:
    #
    # item - The item (Object for ObjectStore, Hash for HashStore) to be tested.
    # conditions - Hash of conditions to be evaluated.
    # block - Optional block that can test the item after the conditions are evaluated.
    #
    # Returns a bool indicating whether the item passed the conditions and matching logic.

    # Internal: Evaluates conditions using AND, i.e. condition && condition && ... [&& block]
    FIND_ALL = Proc.new do |item, conditions, block|
        conditions.all? { |attribute, condition| condition === attr(item, attribute) } &&
          if block then !!block.call(item) else true end
      end
  
    # Internal: Evaluates conditions using OR, i.e. condition || condition || ... [|| block]
    FIND_ANY = Proc.new do |item, conditions, block|
        conditions.any? { |attribute, condition| condition === attr(item, attribute) } ||
          if block then !!block.call(item) else false end
      end

    # Internal: Evaluates conditions using XOR, i.e. condition ^ condition ^ condition ... [^ block]
    FIND_ONE = Proc.new do |item, conditions, block|
        conditions.one? { |attribute, condition| condition === attr(item, attribute) } ^
          if block then !!block.call(item) else false end
      end

    # Internal: Evaluates condition using AND NOT, i.e. !condition && !condition && ... [&& !block]
    FIND_NONE = Proc.new do |item, conditions, block|
        conditions.none? { |attribute, condition| condition === attr(item, attribute) } &&
          if block then !!!block.call(item) else true end
      end

  end
  
end
