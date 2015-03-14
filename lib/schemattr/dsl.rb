module Schemattr
  class DSL
    attr_accessor :attribute_class, :delegated

    def initialize(klass_override = nil, &block)
      @attribute_class = Class.new(klass_override || Attribute)
      @defaults = defaults = {}
      @delegated = []
      instance_eval(&block)
      @attribute_class.define_singleton_method("defaults") { defaults }
    end

    protected

    def field(name, type, options = {})
      @defaults[name.to_s] = options[:default]
      delegated = !!options[:sync]
      if type == :boolean
        _define_setter(name, nil, delegated) do |val|
          self[name] = !!val
          model[options[:sync]] = !!val if options[:sync]
        end
        _define_getter(name, true, delegated)
      else
        _define_setter(name, options[:sync], delegated)
        _define_getter(name, false, delegated)
      end
    end

    private

    def _define_setter(name, sync = nil, delegated = false, &block)
      unless block_given?
        block = lambda do |val|
          self[name] = val
          model[sync] = val if sync
        end
      end
      _define_method("#{name}=", delegated, &block)
    end

    def _define_getter(name, boolean = false, delegated = false, &block)
      block = lambda { self[name] } unless block_given?
      _define_method(name, delegated, &block)
      _define_method("#{name}?", delegated, &block) if boolean
    end

    def _define_method(name, delegated = false, &block)
      @delegated.push(name.to_s) if delegated
      unless attribute_class.instance_methods.include?(name.to_sym)
        attribute_class.send(:define_method, name, &block)
      end
    end
  end
end
