module Refinements
  
  # Enable use of arrays in conditionals.
  refine Array do
    def ===(obj)
      include?(obj)
    end
  end

end
