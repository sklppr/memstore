# encoding: utf-8

# MessagePack de-/serialization.

require "msgpack"

module MemStore

  class HashStore

    # Returns data store in MessagePack format.
    #
    # Raises whatever Hash#to_msgpack raises.
    def to_msgpack
      self.to_hash.to_msgpack
    end
    
    # Writes data store to a file in MessagePack format.
    #
    # file - IO stream of file name as String.
    #
    # Returns number of bytes that were written to the file.
    #
    # Raises whatever IO::write or Hash#to_msgpack raise.
    def to_msgpack_file(file)
      IO.write(file, self.to_msgpack)
    end

    # Restores a data store from MessagePack format.
    #
    # msgpack - Binary data containing a MessagePack-serialized instance of HashStore.
    #
    # Returns instance of HashStore if deserialization succeeded
    #   or nil if deserialization failed.
    #
    # Raises whatever MessagePack::unpack raises.
    def self.from_msgpack(msgpack)
      self.from_hash(MessagePack.unpack(msgpack)) rescue nil
    end
    
    # Restores a data store from a binary file.
    #
    # file - IO stream or file name as String.
    #
    # Returns instance of HashStore or nil as returned by ::from_msgpack
    #   or nil if file doesn’t exist or isn’t readable.
    #
    # Raises whatever IO::read or MessagePack::unpack raise.
    def self.from_msgpack_file(file)
      self.from_msgpack(IO.read(file)) rescue nil
    end

    # Works analogous to ::with_file but de-/serializes takes places in MessagePack format.
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
    # Raises whatever File::open, IO::read, MessagePack::unpack, Hash::to_msgpack or IO::write raise.
    def self.with_msgpack_file(file, key=nil, items={}, &block)
      self.execute_with_file(:from_msgpack_file, :to_msgpack_file, file, key, items, &block)
    end

  end

end