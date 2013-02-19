require "yaml"

module MemStore

  class HashStore
    
    def to_yaml
      self.to_hash.to_yaml
    end
    
    def to_yaml_file(file)
      IO.write file, self.to_yaml
    end

    def self.from_yaml(yaml)
      self.from_hash YAML.load(yaml)
    end
    
    def self.from_yaml_file(file)
      self.from_yaml IO.read(file)
    end

  end

end