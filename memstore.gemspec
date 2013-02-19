# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "memstore/version"

Gem::Specification.new do |gem|
  gem.name          = "memstore"
  gem.version       = MemStore::VERSION
  gem.summary       = %q{A simple, in-memory data store.}
  gem.description   = %q{MemStore is a simple in-memory data store that supports adding, retrieving and deleting items as well as complex search queries and easy serialization.}
  gem.authors       = ["Sebastian Klepper"]
  gem.email         = ["sk@sebastianklepper.com"]
  gem.homepage      = "https://github.com/sklppr/memstore"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
