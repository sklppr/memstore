require "json"

module MemStore

  class HashStore
    
    def to_json
      self.to_hash.to_json
    end
    
    def to_json_file(file)
      IO.write file, self.to_json
    end

    def self.from_json(json)
      self.from_hash JSON.parse(json)
    end
    
    def self.from_json_file(file)
      self.from_json IO.read(file)
    end

  end

end