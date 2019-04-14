# encoding: utf-8

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "schemattr/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "schemattr"
  s.version     = Schemattr::VERSION
  s.authors     = ["jejacks0n"]
  s.email       = ["jejacks0n@gmail.com"]
  s.homepage    = "http://github.com/jejacks0n/bitbot"
  s.summary     = "Schemattr: Simple schema-less column definitions for ActiveRecord"
  s.description = "Write schema-less attributes in ActiveRecord using a helpful and flexible DSL."
  s.license     = "MIT"
  s.files       = Dir["{lib}/**/*"] + ["MIT.LICENSE", "README.md"]

  s.required_ruby_version = "~> 2.4"
end
