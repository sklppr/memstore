# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"

describe MemStore::ObjectStore do
	
	it "can be instantiated with items" do
		h = { a: 1, b: 2, c: 3 }
		mb = MemStore::ObjectStore.new(nil, h)
		mb.items.must_equal h
	end

	it "is the default when instantiating MemStore" do
    	MemStore.new.must_be_instance_of MemStore::ObjectStore
  	end

	it "indexes items by Object#hash by default" do
		o = Object.new
		mb = MemStore::ObjectStore.new.insert(o)
		mb.items[o.hash].must_equal o
	end

	it "indexes items using a custom key" do
		o = Struct.new(:id).new(id: "custom key")
		mb = MemStore::ObjectStore.new(:id).insert(o)
		mb.items[o.id].must_equal o
	end

	it "can be serialized and deserialized" do
		tmp = Tempfile.new("memstore")
		MemStore::ObjectStore.new.to_file tmp
		MemStore.from_file(tmp).must_be_instance_of MemStore::ObjectStore
		tmp.unlink
	end

end

describe MemStore::HashStore do

	it "can be instantiated with items" do
		h = { a: 1, b: 2, c: 3 }
		mb = MemStore::HashStore.new(nil, h)
		mb.items.must_equal h
	end

	it "indexes items by Object#hash by default" do
		h = {}
		mb = MemStore::HashStore.new.insert(h)
		mb.items[h.hash].must_equal h
	end

	it "indexes items using a custom key" do
		h = { id: "custom key" }
		mb = MemStore::HashStore.new(:id).insert(h)
		mb.items[h[:id]].must_equal h
	end

	it "can be serialized and deserialized" do
		tmp = Tempfile.new("memstore")
		MemStore::HashStore.new.to_file tmp
		MemStore.from_file(tmp).must_be_instance_of MemStore::HashStore
		tmp.unlink
	end

	it "can be converted to and from a hash" do
		mb = MemStore::HashStore.new(:id)
		10.times { |i| mb << { id: i } }
		restored = MemStore::HashStore.from_hash(mb.to_hash)
		restored.items.must_equal mb.items
		restored.instance_variable_get(:@key).must_equal :id
	end

end

describe MemStore do

	before do
		@mb = MemStore.new(:to_i)
		# Use float as objects and integer as key
		10.times { |i| @mb << i.to_f }
	end

	it "returns a single item by itself" do
		@mb[3].must_equal 3.0
	end

	it "returns multiple items as an array" do
		@mb[3, 4, 5, 6].must_equal [3.0, 4.0, 5.0, 6.0]
	end

	it "returns multiple items using a Range as an array" do
		@mb[0..9].must_equal @mb.all
	end

	it "deletes a single item by reference and returns it by itself" do
		@mb.delete_item(3.0).must_equal 3.0
	end

	it "deletes multiple items by reference and returns them" do
		@mb.delete_items(3.0, 4.0, 5.0, 6.0).must_equal [3.0, 4.0, 5.0, 6.0]
		@mb.all.must_equal [0.0, 1.0, 2.0, 7.0, 8.0, 9.0]
	end

	it "deletes a single item by key and returns it by itself" do
		@mb.delete_key(3).must_equal 3.0
	end

	it "deletes multiple items by key and returns them as an array" do
		@mb.delete_keys(3, 4, 5, 6).must_equal [3.0, 4.0, 5.0, 6.0]
		@mb.all.must_equal [0.0, 1.0, 2.0, 7.0, 8.0, 9.0]
	end

	it "deletes multiple items by key using a Range and returns them as an array" do
		@mb.delete_keys(3..6).must_equal [3.0, 4.0, 5.0, 6.0]
		@mb.all.must_equal [0.0, 1.0, 2.0, 7.0, 8.0, 9.0]
	end

	it "can be serialized and deserialized" do
		tmp = Tempfile.new("memstore")
		@mb.to_file tmp
		MemStore.from_file(tmp).items.must_equal @mb.items
		tmp.unlink
	end

end

Dummy = Struct.new(:id, :name, :child)

describe MemStore do

	before do
		@mb = MemStore.new
		strings = %w(foo moo boo faa maa baa foa moa boa lao)
		classes = [String, Array]
		10.times do |i|
			@mb << Dummy.new(i, strings[i], classes[i%2].new)
		end
	end

	it "finds all items fulfilling all conditions" do
		matches = @mb.find_all(id: 3..7, child: String)
		matches.collect{ |m| m.id }.must_equal [4, 6]
	end

	it "finds all items fulfilling at least one condition" do
		matches = @mb.find_any(id: 3..7, child: String)
		matches.collect{ |m| m.id }.must_equal [0, 2, 3, 4, 5, 6, 7, 8]
	end

	it "finds all items fulfilling exactly one condition" do
		matches = @mb.find_one(name: /o/, child: String)
		matches.collect{ |m| m.id }.must_equal [1, 4, 7, 9]
	end

	it "finds all items violating at least one condition" do
		matches = @mb.find_not_all(name: /o/, child: String)
		matches.collect{ |m| m.id }.must_equal [1, 3, 4, 5, 7, 9]
	end

	it "finds all items violating all conditions" do
		matches = @mb.find_none(name: /o/, child: String)
		matches.collect{ |m| m.id }.must_equal [3, 5]
	end

	it "finds the first item fulfilling all conditions" do
		match = @mb.first_all(id: 3..7, child: String)
		match.id.must_equal 4
	end

	it "finds the first item fulfilling at least one condition" do
		match = @mb.first_any(id: 3..7, child: String)
		match.id.must_equal 0
	end

	it "finds the first item fulfilling exactly one condition" do
		match = @mb.first_one(name: /o/, child: String)
		match.id.must_equal 1
	end

	it "finds the first item violating at least one condition" do
		match = @mb.first_not_all(name: /o/, child: String)
		match.id.must_equal 1
	end

	it "finds the first item violating all conditions" do
		match = @mb.first_none(name: /o/, child: String)
		match.id.must_equal 3
	end

end
