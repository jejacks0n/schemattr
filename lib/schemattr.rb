require "schemattr/version"
require "schemattr/dsl"
require "schemattr/attribute"
require "schemattr/active_record_extension.rb"

ActiveRecord::Base.send(:include, Schemattr::ActiveRecordExtension) if defined?(ActiveRecord)
