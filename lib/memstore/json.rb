require "json"

module MemStore

  class HashStore
    
    def to_json
      self.to_hash.to_json
    end
    
    def to_json_file(file)
      IO.write(file, self.to_json)
    end

    def self.from_json(json)
      begin self.from_hash(JSON.parse(json)) rescue nil end
    end
    
    def self.from_json_file(file)
      begin self.from_json(IO.read(file)) rescue nil end
    end

  end

end