$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "schemattr/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "schemattr"
  s.version     = Schemattr::VERSION
  s.authors     = ["jejacks0n"]
  s.email       = ["info@modeset.com"]
  s.homepage    = "https://github.com/modeset/schemattr"
  s.summary     = ""
  s.description = ""
  s.license     = "MIT"

  s.files       = Dir["{lib}/**/*"] + ["MIT.LICENSE", "README.md"]
  s.test_files  = `git ls-files -- {spec}/*`.split("\n")
end
