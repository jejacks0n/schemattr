module Schemattr
  class DSL
    attr_accessor :attribute_class

    def initialize(klass_override = nil, &block)
      @attribute_class = Class.new(klass_override || Attribute)
      @defaults = defaults = {}
      instance_eval(&block)
      _define_method("defaults") { defaults }
    end

    protected

    def field(name, type, options = {})
      @defaults[name.to_s] = options[:default]
      if type == :boolean
        _define_setter(name) do |val|
          self[name] = !!val
          model[options[:sync]] = !!val if options[:sync]
        end
        _define_getter(name, true)
      else
        _define_setter(name, options[:sync])
        _define_getter(name)
      end
    end

    private

    def _define_setter(name, sync = nil, &block)
      unless block_given?
        block = lambda do |val|
          self[name] = val
          model[sync] = val if sync
        end
      end
      _define_method("#{name}=", &block)
    end

    def _define_getter(name, boolean = false, &block)
      block = lambda { self[name] } unless block_given?
      _define_method(name, &block)
      _define_method("#{name}?", &block) if boolean
    end

    def _define_method(name, &block)
      unless attribute_class.instance_methods.include?(name.to_sym)
        attribute_class.send(:define_method, name, &block)
      end
    end
  end
end
