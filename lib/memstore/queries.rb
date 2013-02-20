# encoding: utf-8

module MemStore

  class ObjectStore

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

    def count_all(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_ALL) }
    end
    alias_method :count, :count_all

    def count_any(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_ANY) }
    end

    def count_one(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_ONE) }
    end

    def count_not_all(conditions={}, &block)
      all.count { |item| !instance_exec(item, conditions, block, &FIND_ALL) }
    end

    def count_none(conditions={}, &block)
      all.count { |item| instance_exec(item, conditions, block, &FIND_NONE) }
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

  end
  
end
