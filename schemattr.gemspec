# frozen_string_literal: true

require_relative "lib/schemattr/version"
version = Schemattr.version

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "schemattr"
  s.version     = version
  s.summary     = "Schemattr: Simple schema-less column definitions for ActiveRecord."
  s.description = "Write schema-less attributes in ActiveRecord using a helpful and flexible DSL."

  s.required_ruby_version = ">= 2.7.0"

  s.license = "MIT"

  s.author   = "Jeremy Jackson"
  s.email    = "jejacks0n@gmail.com"
  s.homepage = "https://github.com/jejacks0n/schemattr"

  s.files        = Dir["CHANGELOG.md", "MIT-LICENSE", "README.md", "lib/**/*"]
  s.require_path = "lib"

  s.metadata = {
    "homepage_uri"      => s.homepage,
    "source_code_uri"   => s.homepage,
    "bug_tracker_uri"   => s.homepage + "/issues",
    "changelog_uri"     => s.homepage + "/CHANGELOG.md",
    "documentation_uri" => s.homepage + "/README.md",
    "rubygems_mfa_required" => "true",
  }

  s.add_dependency "activerecord", ">= 5.0.0"
end
