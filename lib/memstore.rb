# encoding: utf-8

require "memstore/version"
require "memstore/objectstore"
require "memstore/hashstore"
require "memstore/queries"

module MemStore

  # Shortcut to ObjectStore::new
  def self.new(key=nil)
    ObjectStore.new(key)
  end

end
