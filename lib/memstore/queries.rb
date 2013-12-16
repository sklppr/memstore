class MemStore

  using Refinements

  ### find ###
  
  # Finds items that fulfill all provided conditions.
  #
  # conditions - Hash mapping attributes to conditions (anything that responds to #===).
  # block      - Optional block taking an item and returning a bool. Evaluated after conditions.
  #
  # Returns an Array of items that fulfill all conditions.
  def find_all(conditions={}, &block)
    all.select { |item| match_all(item, conditions, &block) }
  end
  alias_method :find, :find_all
  
  # Finds items that fulfill at least one of the provided conditions.
  def find_any(conditions={}, &block)
    all.select { |item| match_any(item, conditions, &block) }
  end
  
  # Finds items that fulfill exactly one of the provided conditions.
  def find_one(conditions={}, &block)
    all.select { |item| match_one(item, conditions, &block) }
  end
  
  # Finds items that violate at least one of the provided conditions.
  def find_not_all(conditions={}, &block)
    all.reject { |item| match_all(item, conditions, &block) }
  end
  
  # Finds items that violate all provided conditions.
  def find_none(conditions={}, &block)
    all.select { |item| match_none(item, conditions, &block) }
  end
  
  ### first ###
  
  # Finds the first item that fulfills all provided conditions.
  #
  # conditions - Hash mapping attributes to conditions (anything that responds to #===).
  # block      - Optional block taking an item and returning a bool. Evaluated after conditions.
  #
  # Returns the first item that fulfills all conditions.
  def first_all(conditions={}, &block)
    all.detect { |item| match_all(item, conditions, &block) }
  end
  alias_method :first, :first_all
  
  # Finds the first item that fulfills at least one of the provided conditions.
  def first_any(conditions={}, &block)
    all.detect { |item| match_any(item, conditions, &block) }
  end

  # Finds the first item that fulfills exactly one of the provided conditions.
  def first_one(conditions={}, &block)
    all.detect { |item| match_one(item, conditions, &block) }
  end

  # Finds the first item that violates at least one of the provided conditions.
  def first_not_all(conditions={}, &block)
    all.detect { |item| !match_all(item, conditions, &block) }
  end

  # Finds the first item that violates all provided conditions.
  def first_none(conditions={}, &block)
    all.detect { |item| match_none(item, conditions, &block) }
  end

  ### count ###

  # Counts the number of items that fulfill all provided conditions.
  #
  # conditions - Hash mapping attributes to conditions (anything that responds to #===).
  # block      - Optional block taking an item and returning a bool. Evaluated after conditions.
  #
  # Returns the number of items that fulfill all conditions.
  def count_all(conditions={}, &block)
    all.count { |item| match_all(item, conditions, &block) }
  end
  alias_method :count, :count_all

  # Counts the number of items that fulfill at least one of the provided conditions.
  def count_any(conditions={}, &block)
    all.count { |item| match_any(item, conditions, &block) }
  end

  # Counts the number of items that fulfill exactly one of the provided conditions.
  def count_one(conditions={}, &block)
    all.count { |item| match_one(item, conditions, &block) }
  end

  # Counts the number of items that violate at least one of the provided conditions.
  def count_not_all(conditions={}, &block)
    all.count { |item| !match_all(item, conditions, &block) }
  end

  # Counts the number of items that violate all provided conditions.
  def count_none(conditions={}, &block)
    all.count { |item| match_none(item, conditions, &block) }
  end

  ### delete ###

  # Deletes items that fulfill all provided conditions.
  #
  # conditions - Hash mapping attributes to conditions (anything that responds to #===).
  # block      - Optional block taking an item and returning a bool. Evaluated after conditions.
  #
  # Returns an Array of items that fulfill all conditions and were deleted.
  def delete_all(conditions={}, &block)
    @items.inject([]) do |items, (key, item)|
      items << @items.delete(key) if match_all(item, conditions, &block)
      items
    end
  end
  alias_method :delete, :delete_all

  # Deletes items that fulfill at least one of the provided conditions.
  def delete_any(conditions={}, &block)
    @items.inject([]) do |items, (key, item)|
      items << @items.delete(key) if match_any(item, conditions, &block)
      items
    end
  end

  # Deletes items that fulfill exactly one of the provided conditions.
  def delete_one(conditions={}, &block)
    @items.inject([]) do |items, (key, item)|
      items << @items.delete(key) if match_one(item, conditions, &block)
      items
    end
  end

  # Deletes items that violate at least one of the provided conditions.
  def delete_not_all(conditions={}, &block)
    @items.inject([]) do |items, (key, item)|
      items << @items.delete(key) if !match_all(item, conditions, &block)
      items
    end
  end

  # Deletes items that violate all provided conditions.
  def delete_none(conditions={}, &block)
    @items.inject([]) do |items, (key, item)|
      items << @items.delete(key) if match_none(item, conditions, &block)
      items
    end
  end

  private

  # Evaluates conditions using AND, i.e. condition && condition && ... [&& block]
  #
  # item       - The item to be tested.
  # conditions - Hash of conditions to be evaluated.
  # block      - Optional block that can test the item after the conditions are evaluated.
  #
  # Returns a bool indicating whether the item passed the conditions and/or block.
  def match_all(item, conditions={}, &block)
    conditions.all? { |attribute, condition| condition === access_attribute(item, attribute) } &&
      if block_given? then yield(item) else true end
  end

  # Evaluates conditions using OR, i.e. condition || condition || ... [|| block]
  def match_any(item, conditions={}, &block)
    conditions.any? { |attribute, condition| condition === access_attribute(item, attribute) } ||
      if block_given? then yield(item) else false end
  end

  # Evaluates conditions using XOR, i.e. condition ^ condition ^ condition ... [^ block]
  def match_one(item, conditions={}, &block)
    conditions.one? { |attribute, condition| condition === access_attribute(item, attribute) } ^
      if block_given? then yield(item) else false end
  end

  # Evaluates condition using AND NOT, i.e. !condition && !condition && ... [&& !block]
  def match_none(item, conditions={}, &block)
    conditions.none? { |attribute, condition| condition === access_attribute(item, attribute) } &&
      if block_given? then !yield(item) else true end
  end
  
end