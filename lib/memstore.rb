# encoding: utf-8

require "memstore/version"
require "memstore/objectstore"
require "memstore/hashstore"
require "memstore/queries"

module MemStore

  # Shortcut to ObjectStore::new
  def self.new(key=nil, items={})
    ObjectStore.new(key, items)
  end

  # Shortcut to ObjectStore::from_binary
  def self.from_binary(binary)
    ObjectStore.from_binary(binary)
  end

  # Shortcut to ObjectStore::from_file
  def self.from_file(file)
    ObjectStore.from_file(file)
  end

  # Shortcut to ObjectStore::with_file
  def self.with_file(file, key=nil, items={}, &block)
    ObjectStore.with_file(file, key, items, &block)
  end

end
