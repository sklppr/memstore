# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"

describe MemStore::ObjectStore do
  
  before do
    @store = MemStore::ObjectStore.new(:to_i)
    10.times { |i| @store << i.to_f }
  end

  it "can be instantiated with items" do
    h = { a: 1, b: 2, c: 3 }
    store = MemStore::ObjectStore.new(nil, h)
    store.items.must_equal h
  end

  it "is the default when instantiating MemStore" do
    MemStore.new.must_be_instance_of MemStore::ObjectStore
  end

  it "indexes items by Object#hash by default" do
    o = Object.new
    store = MemStore::ObjectStore.new.insert(o)
    store.items[o.hash].must_equal o
  end

  it "indexes items using a custom key" do
    @store.items[0].must_equal 0.0
  end

  it "returns the overall number of items" do
    @store.length.must_equal 10
  end

  it "returns a single item by itself" do
    @store[3].must_equal 3.0
  end

  it "returns multiple items as an array" do
    @store[3, 4, 5, 6].must_equal [3.0, 4.0, 5.0, 6.0]
  end

  it "returns multiple items using a Range as an array" do
    @store[0..9].must_equal @store.all
  end

  it "deletes a single item by reference and returns it by itself" do
    @store.delete_item(3.0).must_equal 3.0
  end

  it "deletes multiple items by reference and returns them" do
    @store.delete_items(3.0, 4.0, 5.0, 6.0).must_equal [3.0, 4.0, 5.0, 6.0]
    @store.all.must_equal [0.0, 1.0, 2.0, 7.0, 8.0, 9.0]
  end

  it "deletes a single item by key and returns it by itself" do
    @store.delete_key(3).must_equal 3.0
  end

  it "deletes multiple items by key and returns them as an array" do
    @store.delete_keys(3, 4, 5, 6).must_equal [3.0, 4.0, 5.0, 6.0]
    @store.all.must_equal [0.0, 1.0, 2.0, 7.0, 8.0, 9.0]
  end

  it "deletes multiple items by key using a Range and returns them as an array" do
    @store.delete_keys(3..6).must_equal [3.0, 4.0, 5.0, 6.0]
    @store.all.must_equal [0.0, 1.0, 2.0, 7.0, 8.0, 9.0]
  end

  it "can be converted to and from binary" do
    restored = MemStore::ObjectStore.from_binary(@store.to_binary)
    restored.must_be_instance_of MemStore::ObjectStore
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @store.instance_variable_get(:@key)
  end

  it "returns nil when conversion from binary fails" do
    MemStore::ObjectStore.from_binary(nil).must_equal nil
    MemStore::ObjectStore.from_binary(Marshal.dump(Object.new)).must_equal nil
  end

  it "returns nil when marshalled object isn’t instance of ObjectStore" do
    MemStore::ObjectStore.from_binary(MemStore::HashStore.new.to_binary).must_equal nil
  end

  it "can be serialized to and deserialized from a binary file" do
    tmp = Tempfile.new("memstore")
    @store.to_file(tmp)
    restored = MemStore::ObjectStore.from_file(tmp)
    restored.must_be_instance_of MemStore::ObjectStore
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @store.instance_variable_get(:@key)
    tmp.unlink
  end

  it "returns nil when deserialization from binary file fails" do
    MemStore::ObjectStore.from_file("does_not_exist").must_equal nil
  end

  it "supports concurrent access to a single binary file" do
    tmp = Tempfile.new("memstore")
    fork do
      MemStore.with_file(tmp, :to_i) { |store| store.insert(1.0, 3.0) }
    end
    fork do
      MemStore.with_file(tmp, :to_i) { |store| store.insert(2.0, 4.0) }
    end
    sleep 0.1
    restored = MemStore.from_file(tmp)
    restored.items.must_equal({1=>1.0, 2=>2.0, 3=>3.0, 4=>4.0})
    tmp.unlink
  end

end
