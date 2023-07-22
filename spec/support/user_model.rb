# frozen_string_literal: true

class User < ActiveRecord::Base
  serialize :settings
  serialize :preferences
  serialize :general
  serialize :custom
  serialize :types

  class CustomAttribute < Schemattr::Attribute
    def custom?
      !self[:custom]
    end
  end

  attribute_schema :settings do
    boolean :active, sync: :active, default: false
    field :snowboarder, :boolean, default: true
    field :skier, :boolean, default: false
  end

  attribute_schema :preferences, delegated: true do
    boolean :likes_cats, default: false
    field :likes_dogs, :boolean, default: true
    field :likes_beer, :boolean, default: true
    field :likes_code, :boolean, from: :likes_programming, default: false
  end

  attribute_schema :general, strict: false do
    string :favorite_quote, default: "none"
  end

  attribute_schema :custom, class: CustomAttribute do
    field :custom, :boolean
  end

  attribute_schema :types do
    field :hash_field, :hash
  end
end
