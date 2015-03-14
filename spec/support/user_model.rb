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
    field :active, :boolean, sync: :active, default: false
    field :snowboarder, :boolean, default: true
    field :skier, :boolean, default: false
  end

  attribute_schema :preferences, delegated: true do
    field :likes_cats, :boolean, default: false
    field :likes_dogs, :boolean, default: true
    field :likes_beer, :boolean, default: true
    field :likes_drinking, :boolean, from: :likes_beer, default: false
  end

  attribute_schema :general, strict: false do
    field :favorite_quote, :string, default: "none"
  end

  attribute_schema :custom, class: CustomAttribute do
    field :custom, :boolean
  end
end
