# encoding: utf-8

require "memstore/version"
require "memstore/objectstore"
require "memstore/hashstore"
require "memstore/queries"

module MemStore

  def self.new(key=nil, items={})
    ObjectStore.new(key, items)
  end

  def self.from_binary(binary)
    ObjectStore.from_binary(binary)
  end

  def self.from_file(file)
    ObjectStore.from_file(file)
  end

  def self.with_file(file, key=nil, items={}, &block)
    ObjectStore.with_file(file, key, items, &block)
  end

end
