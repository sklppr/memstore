class MemStore
  
  using Refinements
  
  # Available actions for queries.
  ACTIONS = %i[ find lazy_find first count delete ]
  
  # Available logics for evaluating conditions.
  LOGICS  = %i[all any one not_all none]
  
  # Runs a query on the data set.
  # 
  # action     - Action to run on selected items. (optional, default is "find")
  # type       - Type or types to filter items before evaluating conditions. (optional)
  # conditions - Conditions to evaluate when selecting items. (optional)
  # fulfill    - Query logic to use when evaluating conditions. (optional, default is "all")
  # &block     - Block to further evaluate an item after conditions have been evaluated. (optional)
  # 
  # Return value depends on action.
  def query(action: :find, type: nil, conditions: {}, fulfill: :all, &block)
    
    # Ensure that action and logic are valid.
    raise "Invalid action: #{action}" unless ACTIONS.include?(action)
    raise "Invalid logic: #{fulfill}"  unless LOGICS.include?(fulfill)
    
    # Run action which will in turn invoke query logic on conditions.
    result = method("execute_#{action}").call(type, conditions, fulfill, &block)
    
  end
  
  # Define shorthand methods for action/logic combinations.
  ACTIONS.each do |action|
    LOGICS.each do |logic|
      define_method "#{action}_#{logic}" do |type=nil, conditions={}, &block|
        
        if type.is_a?(Hash) && conditions.empty?
          # Only conditions were given.
          query(action: action, conditions: type, fulfill: logic, &block)
        else
          query(action: action, conditions: conditions, fulfill: logic, type: type, &block)
        end
        
      end
    end
  end
  
  # Define shortcuts for actions with "all" logic.
  ACTIONS.each do |action|
    alias_method action, "#{action}_all"
  end
  
  private
  
  # Methods to execute actions on items filtered by conditions, type and block.
  # 
  # type       - Type or types to filter items before evaluating conditions.
  # conditions - Conditions to filter items based on attributes.
  # logic      - Query logic for evaluating conditions.
  # &block     - Block to further evaluate an item.
  #
  # All methods return a bool indicating whether the item passed the conditions and/or block.
  
  # Returns all items fulfilling the query.
  def execute_find(type, conditions, logic, &block)
    all(type).select { |item| method("match_#{logic}?").call(item, conditions, &block) }
  end
  
  # Returns lazy enumerator of all items fulfilling the query.
  def execute_lazy_find(type, conditions, logic, &block)
    all(type).lazy.select { |item| method("match_#{logic}?").call(item, conditions, &block) }
  end
  
  # Returns first item fulfilling the query.
  def execute_first(type, conditions, logic, &block)
    all(type).detect { |item| method("match_#{logic}?").call(item, conditions, &block) }
  end
  
  # Returns number of items fulfilling the query.
  def execute_count(type, conditions, logic, &block)
    all(type).count { |item| method("match_#{logic}?").call(item, conditions, &block) }
  end
  
  # Deletes and returns all items fulfilling the query.
  def execute_delete(type, conditions, logic, &block)
    items(type).inject([]) do |items, (key, item)|
      items << @items.delete(key) if method("match_#{logic}?").call(item, conditions, &block)
      items
    end
  end
  
  # Methods to match conditions based on query logic.
  #
  # item       - The item to be tested.
  # conditions - Conditions to be evaluated.
  # &block     - Block to further evaluate an item.
  #
  # All methods return a bool indicating whether the item passed the conditions and/or block.
  
  # Evaluates conditions using AND, i.e. condition && condition && ... [&& block]
  def match_all?(item, conditions, &block)
    conditions.all? { |attr, cond| match_condition?(item, attr, cond) } && (block_given? ? yield(item) : true)
  end

  # Evaluates conditions using OR, i.e. condition || condition || ... [|| block]
  def match_any?(item, conditions, &block)
    conditions.any? { |attr, cond| match_condition?(item, attr, cond) } || (block_given? ? yield(item) : false)
  end

  # Evaluates conditions using XOR, i.e. condition ^ condition ^ condition ... [^ block]
  def match_one?(item, conditions, &block)
    conditions.one? { |attr, cond| match_condition?(item, attr, cond) } ^ (block_given? ? yield(item) : false)
  end

  # Evaluates conditions using NOT AND, i.e. !(condition && condition && ... [&& block])
  def match_not_all?(item, conditions, &block)
    !match_all?(item, conditions, &block)
  end

  # Evaluates conditions using AND NOT, i.e. !condition && !condition && ... [&& !block]
  def match_none?(item, conditions, &block)
    conditions.none? { |attr, cond| match_condition?(item, attr, cond) } && (block_given? ? !yield(item) : true)
  end
  
  # Evaluates if given attribute of given item fulfills given condition.
  def match_condition?(item, attribute, condition)
    condition === access_attribute(item, attribute)
  end
  
end
