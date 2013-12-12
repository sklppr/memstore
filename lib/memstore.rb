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

end
