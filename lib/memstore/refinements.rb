module Refinements
  
  refine Array do
    def ===(obj)
      include?(obj)
    end
  end

end
