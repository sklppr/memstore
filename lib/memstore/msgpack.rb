require "msgpack"

module MemStore

  class HashStore

    def to_msgpack
      self.to_hash.to_msgpack
    end
    
    def to_msgpack_file(file)
      IO.write(file, self.to_msgpack)
    end

    def self.from_msgpack(msgpack)
      begin self.from_hash(MessagePack.unpack(msgpack)) rescue nil end
    end
    
    def self.from_msgpack_file(file)
      begin self.from_msgpack(IO.read(file)) rescue nil end
    end

    def self.with_msgpack_file(file, key=nil, items={}, &block)
      self.run_with_file(:from_msgpack_file, :to_msgpack_file, file, key, items, &block)
    end

  end

end