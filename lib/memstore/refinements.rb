class MemStore
  
  module Refinements
    
    # Enable use of case equality operator to test array inclusion.
    refine Array do
      alias_method :===, :include?
    end
    
  end
  
end
