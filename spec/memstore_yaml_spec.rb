# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"
require "memstore/yaml"

describe MemStore::HashStore do
	
	before do
		@key = :id
		@mb = MemStore::HashStore.new(@key)
		10.times { |i| @mb << { id: i } }
	end

	it "can be converted to and from YAML" do
		restored = MemStore::HashStore.from_yaml(@mb.to_yaml)
		restored.items.must_equal @mb.items
		restored.instance_variable_get(:@key).must_equal @key
	end

	it "can be serialized to and deserialized from a YAML file" do
		tmp = Tempfile.new("memstore_yaml")
		@mb.to_yaml_file(tmp)
		restored = MemStore::HashStore.from_yaml_file(tmp)
		restored.items.must_equal @mb.items
		restored.instance_variable_get(:@key).must_equal @key
		tmp.unlink
	end

end
