require "minitest/autorun"
require "tempfile"

class Dummy # :nodoc:

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

  before do
    @store = MemStore::ObjectStore.new
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

  it "counts all items fulfilling all conditions" do
    count = @store.count_all(id: 3..7, child: String)
    count.must_equal [4, 6].length
  end

  it "counts all items fulfilling at least one condition" do
    count = @store.count_any(id: 3..7, child: String)
    count.must_equal [0, 2, 3, 4, 5, 6, 7, 8].length
  end

  it "counts all items fulfilling exactly one condition" do
    count = @store.count_one(name: /o/, child: String)
    count.must_equal [1, 4, 7, 9].length
  end

  it "counts all items violating at least one condition" do
    count = @store.count_not_all(name: /o/, child: String)
    count.must_equal [1, 3, 4, 5, 7, 9].length
  end

  it "counts all items violating all conditions" do
    count = @store.count_none(name: /o/, child: String)
    count.must_equal [3, 5].length
  end

end
