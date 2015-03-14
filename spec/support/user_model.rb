class User < ActiveRecord::Base
  serialize :settings
  serialize :preferences
  serialize :general
  serialize :custom

  class CustomAttribute < Schemattr::Attribute
    def custom?
      !self[:custom]
    end
  end

  attribute_schema :settings do
    field :active, :boolean, default: false, sync: :active
    field :snowboarder, :boolean, default: true
    field :skier, :boolean, default: false
  end

  attribute_schema :preferences, delegated: true do
    field :likes_cats, :boolean, default: false
    field :likes_dogs, :boolean, default: true
    field :likes_beer, :boolean, default: true
  end

  attribute_schema :general, strict: false do
    field :favorite_quote, :string, default: "none"
  end

  attribute_schema :custom, class: CustomAttribute do
    field :custom, :boolean
  end
end
