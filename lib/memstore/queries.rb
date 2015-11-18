class MemStore

  using Refinements

  # Dynamically define methods to find/count/delete items using different query logic.
  # All methods take the following parameters:
  # 
  # type       - Optional type to filter items by before evaluating conditions.
  # conditions - Hash mapping attributes to conditions (anything that responds to #===).
  # block      - Optional block taking an item and returning a bool. Evaluated after conditions.
  # 
  # Return value is an array of items, with the exception of first_* returning only one item.
  %w[all any one not_all none].each do |variant|
    
    # Return an array of all items matching the query.
    define_method "find_#{variant}" do |type=nil, conditions={}, &block|
      type, conditions = optional_args(type, conditions)
      all(type).select { |item| method("match_#{variant}?").call(item, conditions, &block) }
    end

    # Return a lazy enumerator of all items matching the query.
    define_method "lazy_find_#{variant}" do |type=nil, conditions={}, &block|
      type, conditions = optional_args(type, conditions)
      all(type).lazy.select { |item| method("match_#{variant}?").call(item, conditions, &block) }
    end

    # Return first item matching the query.
    define_method "first_#{variant}" do |type=nil, conditions={}, &block|
      type, conditions = optional_args(type, conditions)
      all(type).detect { |item| method("match_#{variant}?").call(item, conditions, &block) }
    end

    # Return count of all items matching the query.
    define_method "count_#{variant}" do |type=nil, conditions={}, &block|
      type, conditions = optional_args(type, conditions)
      all(type).count { |item| method("match_#{variant}?").call(item, conditions, &block) }
    end

    # Delete and return an array of all items matching the query.
    define_method "delete_#{variant}" do |type=nil, conditions={}, &block|
      type, conditions = optional_args(type, conditions)
      items(type).inject([]) do |items, (key, item)|
        items << @items.delete(key) if method("match_#{variant}?").call(item, conditions, &block)
        items
      end
    end

  end
  
  # Create shortcuts to query methods matching all conditions.
  alias_method :find, :find_all
  alias_method :lazy_find, :lazy_find_all
  alias_method :first, :first_all
  alias_method :count, :count_all
  alias_method :delete, :delete_all

  private

  # Helper to figure out whether type and/or conditions were given.
  # Returns both type and conditions as an array for multiple assignment.
  def optional_args(type, conditions)
    # If type is a hash and conditions are empty, only conditions were given.
    # Return correct conditions and set type to nil. Otherwise just return input.
    if type.is_a?(Hash) && conditions.empty? then [nil, type] else [type, conditions] end
  end

  # Methods to match conditions based on query logic.
  # All methods take the following parameters: 
  #
  # item       - The item to be tested.
  # conditions - Hash of conditions to be evaluated.
  # block      - Optional block that can test the item after the conditions are evaluated.
  #
  # All methods return a bool indicating whether the item passed the conditions and/or block.
  
  # Evaluates conditions using AND, i.e. condition && condition && ... [&& block]
  def match_all?(item, conditions={}, &block)
    conditions.all? { |attribute, condition| condition === access_attribute(item, attribute) } &&
      if block_given? then yield(item) else true end
  end

  # Evaluates conditions using OR, i.e. condition || condition || ... [|| block]
  def match_any?(item, conditions={}, &block)
    conditions.any? { |attribute, condition| condition === access_attribute(item, attribute) } ||
      if block_given? then yield(item) else false end
  end

  # Evaluates conditions using XOR, i.e. condition ^ condition ^ condition ... [^ block]
  def match_one?(item, conditions={}, &block)
    conditions.one? { |attribute, condition| condition === access_attribute(item, attribute) } ^
      if block_given? then yield(item) else false end
  end

  # Evaluates conditions using NOT AND, i.e. !(condition && condition && ... [&& block])
  def match_not_all?(item, conditions={}, &block)
    !match_all?(item, conditions, &block)
  end

  # Evaluates conditions using AND NOT, i.e. !condition && !condition && ... [&& !block]
  def match_none?(item, conditions={}, &block)
    conditions.none? { |attribute, condition| condition === access_attribute(item, attribute) } &&
      if block_given? then !yield(item) else true end
  end
  
end
