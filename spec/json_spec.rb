# encoding: utf-8

require "minitest/autorun"
require "tempfile"
require "memstore"
require "memstore/json"

describe MemStore::HashStore do
  
  before do
    @key = "id"
    @store = MemStore::HashStore.new(@key)
    10.times { |i| @store << { "id" => i.to_s } }
  end

  it "can be converted to and from JSON" do
    restored = MemStore::HashStore.from_json(@store.to_json)
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @key
  end

  it "can be serialized to and deserialized from a JSON file" do
    tmp = Tempfile.new("memstore")
    @store.to_json_file(tmp)
    restored = MemStore::HashStore.from_json_file(tmp)
    restored.items.must_equal @store.items
    restored.instance_variable_get(:@key).must_equal @key
    tmp.unlink
  end

  it "returns nil when conversion from JSON fails" do
    MemStore::HashStore.from_json(nil).must_equal nil
    MemStore::HashStore.from_json(Marshal.dump(Object.new)).must_equal nil
  end

  it "supports concurrent access to a single JSON file" do
    tmp = Tempfile.new("memstore")
    fork do
      MemStore::HashStore.with_json_file(tmp, "id") { |store| store.insert({"id"=>"1"}, {"id"=>"3"}) }
    end
    fork do
      MemStore::HashStore.with_json_file(tmp, "id") { |store| store.insert({"id"=>"2"}, {"id"=>"4"}) }
    end
    sleep 0.1
    restored = MemStore::HashStore.from_json_file(tmp)
    restored.items.must_equal({"1"=>{"id"=>"1"}, "2"=>{"id"=>"2"}, "3"=>{"id"=>"3"}, "4"=>{"id"=>"4"}})
    tmp.unlink
  end

end
