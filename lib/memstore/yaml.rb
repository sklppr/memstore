require "yaml"

module MemStore

  class HashStore
    
    def to_yaml
      self.to_hash.to_yaml
    end
    
    def to_yaml_file(file)
      IO.write(file, self.to_yaml)
    end

    def self.from_yaml(yaml)
      begin self.from_hash(YAML.load(yaml)) rescue nil end
    end
    
    def self.from_yaml_file(file)
      begin self.from_yaml(IO.read(file)) rescue nil end
    end

  end

end