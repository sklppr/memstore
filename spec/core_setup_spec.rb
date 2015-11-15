require "minitest/autorun"
require "memstore"

describe MemStore do

  SimpleDummy = Struct.new(:id)

  def dummy_id(dummy)
    dummy.id
  end

  before do
    @dummy = SimpleDummy.new(42)
    @hash = { id: 42 }
  end
  
  it "accepts items to add at instantiation" do
    items = [1, 2, 3, 4, 5]
    store = MemStore.new(items: items)
    store.items.values.must_equal(items)
  end

  it "indexes items using Object#hash by default" do
    store = MemStore.new
    store << @dummy
    store[@dummy.hash].must_equal(@dummy)
  end

  it "can index items using a given attribute name" do
    store = MemStore.new(key: :id)
    store << @dummy
    store[@dummy.id].must_equal(@dummy)
  end
  
  it "can index items using a given lambda" do
    store = MemStore.new(key: -> item { item.id })
    store << @dummy
    store[@dummy.id].must_equal(@dummy)
  end
  
  it "can index items using a given method" do
    store = MemStore.new(key: method(:dummy_id))
    store << @dummy
    store[@dummy.id].must_equal(@dummy)
  end

  it "accesses attributes using Object#send by default" do
    store = MemStore.new
    store << @dummy
    store.first(id: @dummy.id).must_equal(@dummy)
  end

  it "can access attributes using a given method name" do
    store = MemStore.new(key: :id, access: :[])
    store << @hash
    store[@hash[:id]].must_equal(@hash)
  end

  it "can access attributes using a given lambda" do
    store = MemStore.new(key: :id, access: -> item, attribute { item[attribute] })
    store << @hash
    store[@hash[:id]].must_equal(@hash)
  end

  it "indexes items using Object#hash when an access method but no key accessor is specified" do
    store = MemStore.new(access: :[])
    store << @hash
    store[@hash.hash].must_equal(@hash)
    store[@hash[:id]].must_equal(nil)
  end

end
