# encoding: utf-8

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

end
