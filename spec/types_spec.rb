require "minitest/autorun"
require "memstore"

describe MemStore do

  FooDummy = Struct.new(:type, :id, :foo)
  BarDummy = Struct.new(:type, :id, :bar)

  def dummy_type(dummy)
    dummy.type
  end

  before do
    @foos = (01..10).collect { |i| FooDummy.new("foo", i, i) }
    @bars = (11..20).collect { |i| BarDummy.new("bar", i, i) }
    @items = @foos + @bars
    @store = MemStore.new(key: :id, items: @items)
  end

  # Accessing items by type

  it "provides access to items hash filtered by type" do
    @store.items(FooDummy).values.must_equal(@foos)
  end
  
  it "provides access to items array filtered by type" do
    @store.all(FooDummy).must_equal(@foos)
  end
  
  it "provides access to collection size filtered by type" do
    @store.size(FooDummy).must_equal(@foos.size)
  end

  # Configuring typing

  it "types items using Object#class by default" do
    store = MemStore.new(items: @items)
    store.all(FooDummy).must_equal(@foos)
  end

  it "can type items using a given method name" do
    store = MemStore.new(type: :type, items: @items)
    store.all(FooDummy).must_equal([])
    store.all("foo").must_equal(@foos)
  end
  
  it "can type items using a given lambda" do
    store = MemStore.new(type: Proc.new(&:type), items: @items)
    store.all(FooDummy).must_equal([])
    store.all("foo").must_equal(@foos)
  end
  
  it "can type items using a given method" do
    store = MemStore.new(type: method(:dummy_type), items: @items)
    store.all(FooDummy).must_equal([])
    store.all("foo").must_equal(@foos)
  end

  it "types items using Object#class when an access method but no type accessor is specified" do
    hash = { id: 42, type: "hash" }
    store = MemStore.new(access: :[])
    store.add(hash)
    store.all(Hash).must_equal([hash])
    store.all("hash").must_equal([])
  end

  # Restricting queries by type

  it "finds items fulfilling a query restricted by type" do
    @store.find(FooDummy).must_equal(@foos)
    @store.find_none(BarDummy, id: 15..20).must_equal(@bars[0, 4])
  end

  it "lazily finds items fulfilling a query restricted by type" do
    @store.lazy_find(FooDummy).force.must_equal(@foos)
    @store.lazy_find_none(BarDummy, id: 15..20).force.must_equal(@bars[0, 4])
  end

  it "finds first item fulfilling a query restricted by type" do
    @store.first(FooDummy).must_equal(@foos.first)
    @store.first_none(BarDummy, id: 15..20).must_equal(@bars[0])
  end

  it "counts items fulfilling a query restricted by type" do
    @store.count(FooDummy).must_equal(@foos.count)
    @store.count_none(BarDummy, id: 15..20).must_equal(4)
  end

  it "deletes items fulfilling a query restricted by type" do
    @store.delete(FooDummy).must_equal(@foos)
    @store.all.must_equal(@bars)
    @store.delete_none(BarDummy, id: 15..20).must_equal(@bars[0, 4])
    @store.all.must_equal(@bars[4, 6])
  end
  
  # Handling types that don't have the same attributes
  
  it "by default uses nil when an item doesn't have an attribute" do
    @store.access_attribute(@store.all.first, :bar).must_equal(nil)
  end
  
  it "can query attributes that not all types have" do
    @store.first(bar: 13).must_equal(@bars[2])
    # should also not raise a NoMethodError
  end
  
  it "can collect attributes that not all types have" do
    @store.collect(:bar).must_equal(@foos.map { nil } + @bars.collect(&:bar))
    # should also not raise a NoMethodError
  end

end
