# encoding: utf-8

# JSON de-/serialization.

require "json"

module MemStore

  class HashStore
    
    # Returns data store as a JSON string.
    #
    # Raises whatever Hash#to_json raises.
    def to_json
      self.to_hash.to_json
    end
    
    # Writes data store to a file in JSON format.
    #
    # file - IO stream of file name as String.
    #
    # Returns number of bytes that were written to the file.
    #
    # Raises whatever IO::write or Hash#to_json raise.
    def to_json_file(file)
      IO.write(file, self.to_json)
    end

    # Restores a data store from JSON format.
    #
    # json - String containing a JSON-serialized instance of HashStore.
    #
    # Returns instance of HashStore if deserialization succeeded
    #   or nil if deserialization failed.
    #
    # Raises whatever JSON::parse raises.
    def self.from_json(json)
      self.from_hash(JSON.parse(json)) rescue nil
    end
    
    # Restores a data store from a binary file.
    #
    # file - IO stream or file name as String.
    #
    # Returns instance of HashStore or nil as returned by ::from_json
    #   or nil if file doesn’t exist or isn’t readable.
    #
    # Raises whatever IO::read or JSON::parse raise.
    def self.from_json_file(file)
      self.from_json(IO.read(file)) rescue nil
    end

    # Works analogous to ::with_file but de-/serializes takes places in JSON format.
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
    # Raises whatever File::open, IO::read, JSON::parse, Hash::to_json or IO::write raise.
    def self.with_json_file(file, key=nil, items={}, &block)
      self.execute_with_file(:from_json_file, :to_json_file, file, key, items, &block)
    end

  end

end