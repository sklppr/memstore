require "minitest/autorun"
require "memstore"

describe MemStore do

  before do
    @store = MemStore.new(key: :to_i)
    10.times { |i| @store << i.to_f }
  end

  it "provides access to its internal hash" do
    hash = { 1 => 2.0, 2 => 4.0, 3 => 6.0 }
    @store.items = hash
    @store.items.must_equal(hash)
  end

  it "returns all items as an array" do
    @store.all.must_equal(@store.items.values)
  end

  it "returns the overall number of items" do
    @store.size.must_equal(10)
  end

  it "accepts a single item to add" do
    @store << 10.0
    @store[10].must_equal(10.0)
  end

  it "accepts multiple items to add" do
    @store.add(10.0, 11.0, 12.0)
    @store[10].must_equal(10.0)
    @store[11].must_equal(11.0)
    @store[12].must_equal(12.0)
  end

  it "returns a single item by itself" do
    @store[3].must_equal(3.0)
  end

  it "returns a single item as an array" do
    @store.get(3).must_equal([3.0])
  end

  it "returns multiple items as an array" do
    @store.get(3, 4, 5, 6).must_equal([3.0, 4.0, 5.0, 6.0])
  end

  it "deletes a single item by reference and returns it" do
    @store.delete_item(3.0).must_equal(3.0)
  end

  it "deletes multiple items by reference and returns them" do
    @store.delete_items(3.0, 4.0, 5.0, 6.0).must_equal([3.0, 4.0, 5.0, 6.0])
    @store.all.must_equal([0.0, 1.0, 2.0, 7.0, 8.0, 9.0])
  end

  it "deletes a single item by key and returns it by itself" do
    @store.delete_key(3).must_equal(3.0)
  end

  it "deletes multiple items by key and returns them as an array" do
    @store.delete_keys(3, 4, 5, 6).must_equal([3.0, 4.0, 5.0, 6.0])
    @store.all.must_equal([0.0, 1.0, 2.0, 7.0, 8.0, 9.0])
  end

  it "collects attribute values using the specified access method" do
    @store.collect(:to_i).must_equal(@store.all.map { |n| n.to_i })
  end

end
