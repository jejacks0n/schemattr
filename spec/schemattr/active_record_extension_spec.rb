# frozen_string_literal: true

require "spec_helper"

describe Schemattr::ActiveRecordExtension do
  subject { User.new }

  describe "settings" do
    it "tracks changes through saving" do
      subject.settings.snowboarder = false
      subject.settings.skier = true

      expect(subject.settings.snowboarder).to be_falsey
      expect(subject.settings.snowboarder?).to be_falsey
      expect(subject.settings.skier).to be_truthy
      expect(subject.settings.skier?).to be_truthy

      subject.save!
      subject.reload

      expect(subject.settings.snowboarder).to be_falsey
      expect(subject.settings.snowboarder?).to be_falsey
      expect(subject.settings.skier).to be_truthy
      expect(subject.settings.skier?).to be_truthy

      subject = User.last

      expect(subject.settings.snowboarder).to be_falsey
      expect(subject.settings.snowboarder?).to be_falsey
      expect(subject.settings.skier).to be_truthy
      expect(subject.settings.skier?).to be_truthy
    end

    it "syncs to a cached attribute on the model" do
      subject.settings.active = true
      expect(subject.settings.active?).to eq(true)
      expect(subject.active?).to eq(true)
      expect(subject.read_attribute(:active)).to eq(true)

      subject.save!
      subject = User.last

      expect(subject.active?).to eq(true)
      expect(subject.settings.active?).to eq(true)

      subject.active = false
      expect(subject.active?).to eq(false)
      expect(subject.settings.active?).to eq(false)
      expect(subject.read_attribute(:active)).to eq(false)
    end

    it "allows setting field values via a hash" do
      subject.settings = { skier: true }
      expect(subject.settings.snowboarder?).to eq(true)
      expect(subject.settings.skier?).to eq(true)

      subject.settings = { skier: false, snowboarder: false }
      expect(subject.settings.snowboarder?).to eq(false)
      expect(subject.settings.skier?).to eq(false)
    end

    it "forces setting boolean fields to boolean values" do
      subject.settings = { skier: "foo", active: "true" }
      expect(subject.settings.skier).to eq(true)

      expect(subject.settings.active).to eq(true)
      expect(subject.settings.active?).to eq(true)
      expect(subject.active).to eq(true)
      expect(subject.active?).to eq(true)
    end

    it "coerces sane truthy/falsey values to acutal booleans" do
      subject.update(settings: { active: "1" })
      expect(subject.settings.active).to eq(true)

      subject.update(settings: { active: "0" })
      expect(subject.settings.active).to eq(false)

      subject.update(settings: { active: "on" })
      expect(subject.settings.active).to eq(true)

      subject.update(settings: { active: "off" })
      expect(subject.settings.active).to eq(false)
    end

    it "raises an exception if the value isn't a hash" do
      expect { subject.settings = "foo" }.to raise_error(ArgumentError, "Setting settings requires a hash")
    end

    it "doesn't allow specifying arbitrary fields" do
      expect { subject.settings = { foo: "bar" } }.to raise_error(NoMethodError)
    end
  end

  describe "preferences" do
    it "delegates to the model level" do
      subject.likes_cats = true
      subject.likes_beer = false

      expect(subject.likes_cats?).to eq(true)
      expect(subject.preferences.likes_cats?).to eq(true)
      expect(subject.likes_beer?).to eq(false)
      expect(subject.preferences.likes_beer?).to eq(false)
    end

    it "can migrate one field to a new field" do
      subject[:preferences] = { "likes_programming" => true }
      expect(subject.likes_code?).to eq(true)

      subject.likes_code = false
      expect(subject.likes_code?).to eq(false)

      expect(subject[:preferences]).to eq(subject.preferences.defaults.merge("likes_code" => false))

      subject.save!
      subject.reload

      expect(subject.likes_code?).to eq(false)
    end
  end

  describe "general" do
    it "respects defaults" do
      expect(subject.general.favorite_quote).to eq("none")
    end

    it "allows setting field values to strings" do
      subject.general.favorite_quote = "The truth may be out there, but the lies are inside your head - Terry Pratchett"
      expect(subject.general.favorite_quote).to include("The truth")
    end

    it "allows setting arbitrary fields" do
      subject.general.quote2 = "Time is a drug. Too much of it kills you - Terry Pratchett"
      expect(subject.general.quote2).to include("Time is a drug")
    end
  end

  describe "custom" do
    it "uses a custom attribute class" do
      expect(subject.custom.custom?).to eq(true)
      subject.custom.custom = true
      expect(subject.custom.custom?).to eq(false)
      subject.custom.custom = false
      expect(subject.custom.custom?).to eq(true)
    end
  end
end
