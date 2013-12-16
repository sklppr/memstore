require "minitest/autorun"
require "memstore"

describe MemStore do

  ComplexDummy = Struct.new(:id, :name, :child)

  before do
    @store = MemStore.new(key: :id)
    strings = %w[foo moo boo faa maa baa foa moa boa lao]
    classes = [String, Array]
    10.times { |i| @store << ComplexDummy.new(i, strings[i], classes[i%2].new) }
  end

  # find

  it "finds all items fulfilling all conditions" do
    matches = @store.find_all(id: 3..7, child: String)
    matches.collect(&:id).must_equal([4, 6])
  end

  it "finds all items fulfilling at least one condition" do
    matches = @store.find_any(id: 3..7, child: String)
    matches.collect(&:id).must_equal([0, 2, 3, 4, 5, 6, 7, 8])
  end

  it "finds all items fulfilling exactly one condition" do
    matches = @store.find_one(name: /o/, child: String)
    matches.collect(&:id).must_equal([1, 4, 7, 9])
  end

  it "finds all items violating at least one condition" do
    matches = @store.find_not_all(name: /o/, child: String)
    matches.collect(&:id).must_equal([1, 3, 4, 5, 7, 9])
  end

  it "finds all items violating all conditions" do
    matches = @store.find_none(name: /o/, child: String)
    matches.collect(&:id).must_equal([3, 5])
  end

  # first

  it "finds the first item fulfilling all conditions" do
    match = @store.first_all(id: 3..7, child: String)
    match.id.must_equal(4)
  end

  it "finds the first item fulfilling at least one condition" do
    match = @store.first_any(id: 3..7, child: String)
    match.id.must_equal(0)
  end

  it "finds the first item fulfilling exactly one condition" do
    match = @store.first_one(name: /o/, child: String)
    match.id.must_equal(1)
  end

  it "finds the first item violating at least one condition" do
    match = @store.first_not_all(name: /o/, child: String)
    match.id.must_equal(1)
  end

  it "finds the first item violating all conditions" do
    match = @store.first_none(name: /o/, child: String)
    match.id.must_equal(3)
  end

  # count

  it "counts all items fulfilling all conditions" do
    count = @store.count_all(id: 3..7, child: String)
    count.must_equal([4, 6].length)
  end

  it "counts all items fulfilling at least one condition" do
    count = @store.count_any(id: 3..7, child: String)
    count.must_equal([0, 2, 3, 4, 5, 6, 7, 8].length)
  end

  it "counts all items fulfilling exactly one condition" do
    count = @store.count_one(name: /o/, child: String)
    count.must_equal([1, 4, 7, 9].length)
  end

  it "counts all items violating at least one condition" do
    count = @store.count_not_all(name: /o/, child: String)
    count.must_equal([1, 3, 4, 5, 7, 9].length)
  end

  it "counts all items violating all conditions" do
    count = @store.count_none(name: /o/, child: String)
    count.must_equal([3, 5].length)
  end

  # delete

  it "deletes all items fulfilling all conditions" do
    deleted = @store.delete_all(id: 3..7, child: String)
    deleted.collect(&:id).must_equal([4, 6])
    @store.all.collect(&:id).must_equal([0, 1, 2, 3, 5, 7, 8, 9])
  end

  it "deletes all items fulfilling at least one condition" do
    deleted = @store.delete_any(id: 3..7, child: String)
    deleted.collect(&:id).must_equal([0, 2, 3, 4, 5, 6, 7, 8])
    @store.all.collect(&:id).must_equal([1, 9])
  end

  it "deletes all items fulfilling exactly one condition" do
    deleted = @store.delete_one(name: /o/, child: String)
    deleted.collect(&:id).must_equal([1, 4, 7, 9])
    @store.all.collect(&:id).must_equal([0, 2, 3, 5, 6, 8])
  end

  it "deletes all items violating at least one condition" do
    deleted = @store.delete_not_all(name: /o/, child: String)
    deleted.collect(&:id).must_equal([1, 3, 4, 5, 7, 9])
    @store.all.collect(&:id).must_equal([0, 2, 6, 8])
  end

  it "deletes all items violating all conditions" do
    deleted = @store.delete_none(name: /o/, child: String)
    deleted.collect(&:id).must_equal([3, 5])
    @store.all.collect(&:id).must_equal([0, 1, 2, 4, 6, 7, 8, 9])
  end

  # Array refinement

  it "finds items included in an Array" do
    matches = @store.find(id: [1, 3, 5])
    matches.collect(&:id).must_equal([1, 3, 5])
  end

end
