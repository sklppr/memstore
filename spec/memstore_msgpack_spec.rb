# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"
require "memstore/msgpack"

describe MemStore::HashStore do
  
  before do
    @key = "id"
    @store = MemStore::HashStore.new(@key)
    10.times { |i| @store << { "id" => i } }
  end

  it "can be converted to and from MessagePack" do
    restored = MemStore::HashStore.from_msgpack(@store.to_msgpack)
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @key
  end

  it "can be serialized to and deserialized from a MessagePack file" do
    tmp = Tempfile.new("memstore")
    @store.to_msgpack_file(tmp)
    restored = MemStore::HashStore.from_msgpack_file(tmp)
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @key
    tmp.unlink
  end

end
