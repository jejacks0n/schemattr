module Schemattr
  module ActiveRecordExtension
    module ClassMethods
      def attribute_schema(name, options = {}, &block)
        raise ArgumentError, "No schema provided, block expected for schemaless_attribute." unless block_given?

        name = name.to_sym
        attribute_class = DSL.new(options[:class], &block).attribute_class
        delegate(*attribute_class.instance_methods(false), to: name) if options[:delegated]

        define_method "#{name}=" do |val|
          raise ArgumentError, "Setting #{name} requires a hash" unless val.is_a?(Hash)
          delegator = send(name)
          val.each do |k, v|
            endpoint = options[:delegated] && self.respond_to?("#{k}=") ? self : delegator
            endpoint.send("#{k}=", v)
          end
          val
        end

        define_method "#{name}" do
          _schemaless_attributes[name] ||= attribute_class.new(self, name, options[:strict] == false)
        end
      end
    end

    def self.included(base = nil, &_block)
      base.extend(ClassMethods)
    end

    def reload(*_args)
      _schemaless_attributes.keys.each { |name| _schemaless_attributes[name] = nil }
      super
    end

    private

    def _schemaless_attributes
      @_schemaless_attributes ||= {}
    end
  end
end
