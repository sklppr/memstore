require "msgpack"

module MemStore

  class HashStore

    def to_msgpack
      self.to_hash.to_msgpack
    end
    
    def to_msgpack_file(file)
      IO.write file, self.to_msgpack
    end

    def self.from_msgpack(msgpack)
      self.from_hash MessagePack.unpack(msgpack)
    end
    
    def self.from_msgpack_file(file)
      self.from_msgpack IO.read(file)
    end

  end

end