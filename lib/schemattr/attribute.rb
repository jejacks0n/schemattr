module Schemattr
  class Attribute
    attr_accessor :model, :attr_name, :hash

    def initialize(model, attr_name, allow_arbitrary_attributes = false)
      @model = model
      @attr_name = attr_name
      @allow_arbitrary_attributes = allow_arbitrary_attributes
      @hash = defaults.merge(model[attr_name] || {})
    end

    def field_names
      (self.class.defaults.keys || []).map { |k| k.to_sym }
    end

    def defaults
      self.class.defaults
    end

    private

    def method_missing(m, *args)
      if @allow_arbitrary_attributes
        self[$1] = args[0] if args.length == 1 && /^(\w+)=$/ =~ m
        self[m.to_s.gsub(/\?$/, "")]
      else
        raise NoMethodError, "undefined method '#{m}' for #{self.class}"
      end
    end

    def migrate_value(val, from)
      return val unless from
      if (old_val = self[from]).nil?
        val
      else
        @hash.delete(from.to_s)
        old_val
      end
    end

    def sync_value(val, to)
      model[to] = val if to
      val
    end

    def []=(key, val)
      hash[key.to_s] = val
      model[attr_name] = hash
      val
    end

    def [](key)
      hash[key.to_s]
    end
  end
end
