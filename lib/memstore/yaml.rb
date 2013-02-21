# encoding: utf-8

# YAML de-/serialization.

require "yaml"

module MemStore

  class HashStore
    
    # Returns data store as a YAML string.
    #
    # Raises whatever Hash#to_yaml raises.
    def to_yaml
      self.to_hash.to_yaml
    end
    
    # Writes data store to a file in YAML format.
    #
    # file - IO stream of file name as String.
    #
    # Returns number of bytes that were written to the file.
    #
    # Raises whatever IO::write or Hash#to_yaml raise.
    def to_yaml_file(file)
      IO.write(file, self.to_yaml)
    end

    # Restores a data store from YAML format.
    #
    # yaml - String containing a YAML-serialized instance of HashStore.
    #
    # Returns instance of HashStore if deserialization succeeded
    #   or nil if deserialization failed.
    #
    # Raises whatever YAML::parse raises.
    def self.from_yaml(yaml)
      begin
        self.from_hash(YAML.load(yaml))
      rescue StandardError, Psych::SyntaxError
        nil
      end
    end
    
    # Restores a data store from a binary file.
    #
    # file - IO stream or file name as String.
    #
    # Returns instance of HashStore or nil as returned by ::from_yaml
    #   or nil if file doesn’t exist or isn’t readable.
    #
    # Raises whatever IO::read or YAML::parse raise.
    def self.from_yaml_file(file)
      self.from_yaml(IO.read(file)) rescue nil
    end

    # Works analogous to ::with_file but de-/serializes takes places in YAML format.
    #
    # file - IO stream or file name as String.
    # key - Optional key attribute (Symbol or String) to use in ::new (default: nil).
    # items - Optional items Hash to use in ::new (default: empty Hash).
    # block - Block that will be called after a data store was restored or created.
    #
    # Yields the restored or newly created data store.
    #
    # Returns whatever the block returns.
    #
    # Raises whatever File::open, IO::read, YAML::parse, Hash::to_yaml or IO::write raise.
    def self.with_yaml_file(file, key=nil, items={}, &block)
      self.execute_with_file(:from_yaml_file, :to_yaml_file, file, key, items, &block)
    end

  end

end