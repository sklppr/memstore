# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"

class Dummy

  attr_accessor :id, :name, :child
  
  def initialize(id, name=nil, child=nil)
    @id, @name, @child = id, name, child
  end

  def ==(obj)
    obj.is_a?(Dummy) &&
    obj.id == @id &&
    obj.name == @name &&
    obj.child == @child
  end

end

describe MemStore::ObjectStore do
  
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
    o = Dummy.new("custom key")
    store = MemStore::ObjectStore.new(:id).insert(o)
    store.items[o.id].must_equal o
  end

  it "can be converted to and from binary" do
    o = Dummy.new("custom key")
    store = MemStore::ObjectStore.new(:id).insert(o)
    restored = MemStore::ObjectStore.from_binary(store.to_binary)
    restored.must_be_instance_of MemStore::ObjectStore
    restored.items.must_equal store.items
    restored.instance_variable_get(:@key).must_equal :id
  end

  it "returns nil when conversion from binary fails" do
    MemStore::ObjectStore.from_binary(nil).must_equal nil
  end

  it "can be serialized to and deserialized from a binary file" do
    tmp = Tempfile.new("memstore")
    o = Dummy.new("custom key")
    store = MemStore::ObjectStore.new(:id).insert(o)
    store.to_file(tmp)
    restored = MemStore::ObjectStore.from_file(tmp)
    restored.must_be_instance_of MemStore::ObjectStore
    restored.items.must_equal store.items
    restored.instance_variable_get(:@key).must_equal :id
    tmp.unlink
  end

  it "returns nil when deserialization from binary file fails" do
    MemStore::ObjectStore.from_file("does_not_exist").must_equal nil
  end

end

describe MemStore::HashStore do

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
    h = { id: "custom key" }
    store = MemStore::HashStore.new(:id).insert(h)
    store.items[h[:id]].must_equal h
  end

  it "can be converted to and from binary" do
    store = MemStore::HashStore.new(:id).insert({ id: "custom key" })
    restored = MemStore::HashStore.from_binary(store.to_binary)
    restored.must_be_instance_of MemStore::HashStore
    restored.items.must_equal store.items
    restored.instance_variable_get(:@key).must_equal :id
  end

  it "can be serialized to and deserialized from a binary file" do
    tmp = Tempfile.new("memstore")
    store = MemStore::HashStore.new(:id).insert({ id: "custom key" })
    store.to_file(tmp)
    restored = MemStore::HashStore.from_file(tmp)
    restored.must_be_instance_of MemStore::HashStore
    restored.items.must_equal store.items
    restored.instance_variable_get(:@key).must_equal :id
    tmp.unlink
  end

  it "can be converted to and from a hash" do
    store = MemStore::HashStore.new(:id)
    10.times { |i| store << { id: i } }
    restored = MemStore::HashStore.from_hash(store.to_hash)
    restored.items.must_equal store.items
    restored.instance_variable_get(:@key).must_equal :id
  end

  it "returns nil when conversion from hash fails" do
    MemStore::HashStore.from_hash(nil).must_equal nil
    MemStore::HashStore.from_hash({}).must_equal nil
  end

end

describe MemStore do

  before do
    @store = MemStore.new(:to_i)
    # Use float as objects and integer as key
    10.times { |i| @store << i.to_f }
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

end

describe MemStore do

  before do
    @store = MemStore.new
    strings = %w(foo moo boo faa maa baa foa moa boa lao)
    classes = [String, Array]
    10.times do |i|
      @store << Dummy.new(i, strings[i], classes[i%2].new)
    end
  end

  it "finds all items fulfilling all conditions" do
    matches = @store.find_all(id: 3..7, child: String)
    matches.collect{ |m| m.id }.must_equal [4, 6]
  end

  it "finds all items fulfilling at least one condition" do
    matches = @store.find_any(id: 3..7, child: String)
    matches.collect{ |m| m.id }.must_equal [0, 2, 3, 4, 5, 6, 7, 8]
  end

  it "finds all items fulfilling exactly one condition" do
    matches = @store.find_one(name: /o/, child: String)
    matches.collect{ |m| m.id }.must_equal [1, 4, 7, 9]
  end

  it "finds all items violating at least one condition" do
    matches = @store.find_not_all(name: /o/, child: String)
    matches.collect{ |m| m.id }.must_equal [1, 3, 4, 5, 7, 9]
  end

  it "finds all items violating all conditions" do
    matches = @store.find_none(name: /o/, child: String)
    matches.collect{ |m| m.id }.must_equal [3, 5]
  end

  it "finds the first item fulfilling all conditions" do
    match = @store.first_all(id: 3..7, child: String)
    match.id.must_equal 4
  end

  it "finds the first item fulfilling at least one condition" do
    match = @store.first_any(id: 3..7, child: String)
    match.id.must_equal 0
  end

  it "finds the first item fulfilling exactly one condition" do
    match = @store.first_one(name: /o/, child: String)
    match.id.must_equal 1
  end

  it "finds the first item violating at least one condition" do
    match = @store.first_not_all(name: /o/, child: String)
    match.id.must_equal 1
  end

  it "finds the first item violating all conditions" do
    match = @store.first_none(name: /o/, child: String)
    match.id.must_equal 3
  end

end
