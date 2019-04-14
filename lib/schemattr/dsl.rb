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
          define(name, false, options)
        end
      end

      def string(name, options = {})
        define name, false, options, setter: lambda { |val| sync_value(self[name] = val.to_s, options[:sync]) }
      end

      def integer(name, options = {})
        define name, false, options, setter: lambda { |val| sync_value(self[name] = val.to_i, options[:sync]) }
      end

      def float(name, options = {})
        define name, false, options, setter: lambda { |val| sync_value(self[name] = val.to_f, options[:sync]) }
      end

      def datetime(name, options = {})
        define name, false, options
      end

      def date(name, options = {})
        define name, false, options
      end

      def boolean(name, options = {})
        define name, true, options, setter: lambda { |val|
          bool = ActiveRecord::Type::Boolean.new.deserialize(val)
          sync_value(self[name] = bool, options[:sync])
        }
      end

      alias_method :text, :string
      alias_method :bigint, :integer
      alias_method :decimal, :float
      alias_method :time, :datetime

    private

      def define(name, boolean, options, blocks = {})
        setter = blocks[:setter] || lambda { sync_value(self[name] = val, options[:sync]) }
        getter = blocks[:getter] || lambda { migrate_value(self[name], options[:from]) }
        default_for(name, options[:default])
        method_for("#{name}=", options[:sync], &setter)
        method_for(name, options[:sync], &getter)
        alias_for("#{name}?", name, options[:sync]) if boolean
      end

      def default_for(name, default)
        @defaults[name.to_s] = default
      end

      def method_for(name, delegated = false, &block)
        @delegated.push(name.to_s) if delegated
        unless attribute_class.instance_methods.include?(name.to_sym)
          attribute_class.send(:define_method, name, &block)
        end
      end

      def alias_for(new, old, delegated)
        @delegated.push(new.to_s) if delegated
        attribute_class.send(:alias_method, new, old) unless attribute_class.instance_methods.include?(new.to_sym)
      end
  end
end
