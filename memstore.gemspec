$:.push File.expand_path("../lib", __FILE__)
require "memstore/version"

Gem::Specification.new do |gem|
  gem.name                  = "memstore"
  gem.version               = MemStore::VERSION
  gem.required_ruby_version = ">= 2.1.0dev"
  gem.summary               = "A simple in-memory data store."
  gem.description           = "MemStore is a simple in-memory data store that supports complex search queries."
  gem.authors               = ["Sebastian Klepper"]
  gem.license               = "MIT"
  gem.homepage              = "https://github.com/sklppr/memstore"
  gem.files                 = `git ls-files`.split($/)
  gem.executables           = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files            = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths         = ["lib"]
end
