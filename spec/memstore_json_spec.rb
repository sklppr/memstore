# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"
require "memstore/json"

describe MemStore::HashStore do
	
	before do
		@key = "id"
		@mb = MemStore::HashStore.new(@key)
		10.times { |i| @mb << { "id" => i.to_s } }
	end

	it "can be converted to and from JSON" do
		restored = MemStore::HashStore.from_json(@mb.to_json)
		restored.items.must_equal @mb.items
		restored.instance_variable_get(:@key).must_equal @key
	end

	it "can be serialized to and deserialized from a JSON file" do
		tmp = Tempfile.new("memstore_json")
		@mb.to_json_file(tmp)
		restored = MemStore::HashStore.from_json_file(tmp)
		restored.items.must_equal @mb.items
		restored.instance_variable_get(:@key).must_equal @key
		tmp.unlink
	end

end
