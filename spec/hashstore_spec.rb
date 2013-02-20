require "minitest/autorun"
require "tempfile"
require "memstore"

describe MemStore::HashStore do

  before do
    @store = MemStore::HashStore.new(:id)
    10.times { |i| @store << { id: i } }
  end

  it "can be instantiated with items" do
    h = { a: 1, b: 2, c: 3 }
    store = MemStore::HashStore.new(nil, h)
    store.items.must_equal h
  end

  it "indexes items by Object#hash by default" do
    h = {}
    store = MemStore::HashStore.new.insert(h)
    store.items[h.hash].must_equal h
  end

  it "indexes items using a custom key" do
    @store.items[0].must_equal @store.all.first
  end

  it "can be converted to and from binary" do
    restored = MemStore::HashStore.from_binary(@store.to_binary)
    restored.must_be_instance_of MemStore::HashStore
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @store.instance_variable_get(:@key)
  end

  it "can be serialized to and deserialized from a binary file" do
    tmp = Tempfile.new("memstore")
    @store.to_file(tmp)
    restored = MemStore::HashStore.from_file(tmp)
    restored.must_be_instance_of MemStore::HashStore
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @store.instance_variable_get(:@key)
    tmp.unlink
  end

  it "can be converted to and from a hash" do
    restored = MemStore::HashStore.from_hash(@store.to_hash)
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @store.instance_variable_get(:@key)
  end

  it "returns nil when conversion from hash fails" do
    MemStore::HashStore.from_hash(nil).must_equal nil
    MemStore::HashStore.from_hash({}).must_equal nil
  end

end
