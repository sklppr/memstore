# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"

describe MemStore::ObjectStore do
  
  before do
    @store = MemStore::ObjectStore.new(:to_i)
    10.times { |i| @store << i.to_f }
  end

  it "is the default when instantiating MemStore" do
    MemStore.new.must_be_instance_of MemStore::ObjectStore
  end

  it "indexes items by Object#hash by default" do
    o = Object.new
    store = MemStore::ObjectStore.new.add(o)
    store.items[o.hash].must_equal o
  end

  it "indexes items using a custom key" do
    @store.items[0].must_equal 0.0
  end

  it "returns the overall number of items" do
    @store.size.must_equal 10
  end

  it "returns a single item by itself" do
    @store[3].must_equal 3.0
  end

  it "returns a single item as an array" do
    @store.get(3).must_equal [3.0]
  end

  it "returns multiple items as an array" do
    @store.get(3, 4, 5, 6).must_equal [3.0, 4.0, 5.0, 6.0]
  end

  it "deletes a single item by reference and returns it" do
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

end
