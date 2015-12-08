module Schemattr
  class DSL
    attr_accessor :attribute_class, :delegated, :defaults

    def initialize(klass_override = nil, &block)
      @attribute_class = Class.new(klass_override || Attribute)
      @delegated = []
      @defaults = defaults = {}

      instance_eval(&block)

      @attribute_class.define_singleton_method("defaults") { defaults }
    end

    protected

    def field(name, type, options = {})
      if respond_to?(type, true)
        send(type, name, options)
      else
        _define(name, false, options)
      end
    end

    def string(name, options = {})
      _define name, false, options, setter: lambda { |val| sync_value(self[name] = val.to_s, options[:sync]) }
    end

    def integer(name, options = {})
      _define name, false, options, setter: lambda { |val| sync_value(self[name] = val.to_i, options[:sync]) }
    end

    def float(name, options = {})
      _define name, false, options, setter: lambda { |val| sync_value(self[name] = val.to_f, options[:sync]) }
    end

    def datetime(name, options = {})
      _define name, false, options
    end

    def date(name, options = {})
      _define name, false, options
    end

    def boolean(name, options = {})
      _define name, true, options, setter: lambda { |val|
        bool = ActiveRecord::Type::Boolean.new.type_cast_from_user(val)
        sync_value(self[name] = bool, options[:sync])
      }
    end

    alias_method :text, :string
    alias_method :bigint, :integer
    alias_method :decimal, :float
    alias_method :time, :datetime

    private

    def _define(name, boolean, options, blocks = {})
      setter = blocks[:setter] || lambda { sync_value(self[name] = val, options[:sync]) }
      getter = blocks[:getter] || lambda { migrate_value(self[name], options[:from]) }
      _default(name, options[:default])
      _method("#{name}=", options[:sync], &setter)
      _method(name, options[:sync], &getter)
      _alias("#{name}?", name, options[:sync]) if boolean
    end

    def _default(name, default)
      @defaults[name.to_s] = default
    end

    def _method(name, delegated = false, &block)
      @delegated.push(name.to_s) if delegated
      unless attribute_class.instance_methods.include?(name.to_sym)
        attribute_class.send(:define_method, name, &block)
      end
    end

    def _alias(new, old, delegated)
      @delegated.push(new.to_s) if delegated
      unless attribute_class.instance_methods.include?(new.to_sym)
        attribute_class.send(:alias_method, new, old)
      end
    end
  end
end
