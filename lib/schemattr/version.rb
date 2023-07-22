# frozen_string_literal: true

module Schemattr
  # Returns the currently loaded version as a +Gem::Version+.
  def self.version
    Gem::Version.new(VERSION::STRING)
  end

  module VERSION
    MAJOR = 0
    MINOR = 1
    TINY  = 0
    PRE   = nil

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
  end
end
