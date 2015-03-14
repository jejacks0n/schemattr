Schemattr
=========

[![Gem Version](https://img.shields.io/gem/v/schemattr.svg)](http://badge.fury.io/rb/schemattr)
[![Build Status](https://img.shields.io/travis/modeset/schemattr.svg)](https://travis-ci.org/modeset/schemattr)
[![Code Climate](https://codeclimate.com/github/modeset/schemattr/badges/gpa.svg)](https://codeclimate.com/github/modeset/schemattr)
[![Test Coverage](https://codeclimate.com/github/modeset/schemattr/badges/coverage.svg)](https://codeclimate.com/github/modeset/schemattr)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
[![Dependency Status](https://gemnasium.com/modeset/schemattr.svg)](https://gemnasium.com/modeset/schemattr)

Schemattr is an ActiveRecord extension that provides a helpful schema-less attribute DSL. It can be used to define a
simple schema for a single attribute that can change over time without having to migrate existing data.

### Background

Let's say you have a User model, and that model has a simple concept of settings -- just one for now. It's a boolean
named `opted_in`, and it means that the user is opted in to receive email updates. Sweet, we go add a migration for this
setting and migrate. Ship it, we're done with that feature.

Ok, so now it's a year later and your project has grown a lot. You have over 4MM users, and in that year there's been a
lot of business requirements that necessitated new settings for users. Each setting has been added ad hoc, as needed --
there's now three email lists, and users can opt in and out of each one independently.

This is where Schemattr comes in. Adding a new setting, or changing the name of an existing setting is non-trivial at
this point of your projects life-cycle, and requires a multi-step migration. You'll need to add the column (don't set a
default for that column, because that locks the table!), then you'll need to update each record in batches, once
complete you'll set a default, and finally you'll want to add a null constraint. This can become a hassle, and
introduces complexity to your deployments.

Schemattr allows you to move all of those settings into a single JSON (or similarly serialized) column. It can behave as
though the column is defined on the record itself through delegation, allows providing overrides for getter/setter
methods, can keep a real column synced with one if its fields, and more.

If you're using Schemattr and want to add a new setting field, it's as simple as adding a new field to the attribute
schema and setting a default right there in the code. No migrations, no hassles, easy deployment.


## Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
  - [Delegating](#delegating)
  - [Strict mode](#strict-mode-vs-arbitrary-fields)
  - [Overriding](#overriding-functionality)
  - [Renaming fields](#renaming-fields)
  - [Syncing attributes](#syncing-attributes)


## Installation

Add it to your Gemfile:
```ruby
gem 'schemattr'
```

And then execute:
```shell
$ bundle
```

Or install it yourself as:
```shell
$ gem install schemattr
```


## Usage

In the examples we assume there's already a User model and table.

First, let's create a migration to add your schema-less attribute. In postgres you can use a JSON column. We use the
postgres JSON type as our example because the JSON type allows queries and indexing, and hstore does annoying things to
booleans. We don't need to set our default value to an empty object because Schemattr handles that for us.

*Note*: If you're using a different database provider, like sqlite3 for instance, you can use a text column and tell
ActiveRecord to serialize that column (e.g. `serialize :settings` in your model). Though, you won't be able to easily
query in these cases so consider your options.

```ruby
class AddSettingsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :settings, :json
  end
end
```

Schemattr hooks into ActiveRecord and provides the `attribute_schema` method on any model that inherits from
ActiveRecord. This method provides a simple DSL that allows you to define the schema for the attribute. You can define
various fields, specify their types, defaults if needed, and additional options.

```ruby
class User < ActiveRecord::Base
  attribute_schema :settings do
    field :opted_in, :boolean, default: true
    field :email_list_advanced, :boolean, default: false
    field :email_list_expert, :boolean, default: false
  end
end
```

Notice that we've done nothing else, but we already have a working version of what we want. It's shippable.

```
user = User.new
user.settings.opted_in? # => true
user.settings.email_group_advanced? # => false 
user.settings.email_group_expert? # => false 
```

If we save the user at this point, these settings will be persisted. We can also make changes to them at this point, and
when they're persisted they'll include whatever we've changed them to be. If we don't save the user, that's ok too --
they'll just be the defaults if we ever ask again.

### Delegating

If you don't like the idea of having to access these attributes at `user.settings` you can specify that you'd like them
delegated. This adds delegation of the methods that exist on settings to the User instances.

```ruby
  attribute_schema :settings, delegated: true do
    field :opted_in, :boolean, default: true
  end
```

```ruby
user = User.new
user.opted_in = false
user.settings.opted_in? # => false
user.opted_in? # => false
```

### Strict mode vs. arbitrary fields

By default, Schemattr doesn't allow arbitrary fields to be added, but it supports it. When strict mode is disabled, it
allows any arbitrary field to be set or asked for.

*Note*: When delegated and strict mode is disabled, you cannot set arbitrary fields on the model directly and must
access them through the attribute that you've defined -- in our case, it's `settings`.

```ruby
  attribute_schema :settings, delegated: true, strict: false do
    field :opted_in, :boolean, default: true
  end
```

```ruby
user = User.new
user.settings.foo # => nil
user.settings.foo = "bar"
user.settings.foo # => "bar"
user.foo # => NoMethodError
```

### Overriding

Schemattr provides the ability to specify your own attribute class. By doing so you can provide your own getters and
setters and do more complex logic. In this example we're providing the inverse of `opted_in` with an `opted_out` psuedo
field.

```ruby
class UserSettings < Schemattr::Attribute
  def opted_out
    !self[:opted_in]
  end
  alias :opted_out, :opted_out?
  
  def opted_out=(val)
    opted_in = !val
  end
end
```

```ruby
  attribute_schema :settings, class: UserSettings do
    field :opted_in, :boolean, default: true
  end
```

```ruby
user = User.new
user.settings.opted_out? # => false
user.settings.opted_in? # => true
user.settings.opted_out = true
user.settings.opted_in? # => false
```

Our custom `opted_out` psuedo field won't be persisted, because it's not a defined field and is just an accessor for an
existing field that is persisted (`opted_in`).

#### Getters and setters

When overriding the attribute class with your own, you can provide your own custom getters and setters as well. These
will not be overridden by whatever Schemattr thinks they should do. Take this example, where when someone turns on or
off a setting we want to subscribe/unsubscribe them to an email list via a third party.

```ruby
class UserSettings < Schemattr::Attribute
  def opted_in=(val)
    if val
      SubscribeEmail.perform_async(model.email)
    else
      UnsubscribeEmail.perform_async(model.email)
    end
    # there is no super, so you must set it manually.
    self[:opted_in] = val
  end
end
```

*Note*: This is not a real world scenario but serves our purposes of describing an example. 

### Renaming fields

Schemattr makes it easy to rename fields as well. Let's say you've got a field named `opted_in`, as the examples have
shown thus far. But you've added new email lists, and you think `opted_in` is too vague. Like, opted in for what?

We can create a new field that is correctly named, and specify what attribute we want to pull the value from.

```ruby
  attribute_schema :settings do
    # field :opted_in, :boolean, default: true
    field :email_list_beginner, :boolean, from: :opted_in, default: true
  end
```

Specifying the `from: :opted_in` option will tell Schemattr to look for the value that may have already been defined in
`opted_in` before the rename. This allows for slow migrations, but you can also write a migration to ensure this happens
quickly.

### Syncing attributes

There's a down side to keeping some things internal to this settings attribute. You can query JSON types in postgres,
but it may not be optimal given your indexing strategy. Schemattr provides a mechanism to keep an attribute in sync, but
it's important to understand it and handle it with care.

Let's say we want to be able to be able to easily query users who have opted in. We can add the `opted_in` column to (or
leave it, as the case may be) on the users table.

```ruby
  attribute_schema :settings do
    field :email_list_beginner, :boolean, default: true, sync: :opted_in
  end
```

```ruby
user = User.new
user.settings.email_list_beginner = false
user.read_attribute(:opted_in) # => false
user.save!
User.where(opted_in: false) # => user
```

By adding the sync option to the field, Schemattr will try to keep that attribute in sync. There are some caveats that
can lead to confusion however.

First, when you do this, it forces delegation of `user.opted_in` to `user.settings.opted_in` -- this is to make keeping
things in sync easier. The second issue can arise is when this attribute is set directly in the database -- which means
using things like `user.update_column(:opted_in, false)`, and `User.update_all(opted_in: false)` will allow things to
get out of sync.


## Querying a JSON column

This has come up a little bit, and so it's worth documenting -- though it has very little to do with Schemattr. When you
have a JSON column in postgres, you can query values from within that column in various ways.

[The documentation](http://www.postgresql.org/docs/9.4/static/functions-json.html) can be a little hard to grok, so
these are the common scenarios that we've used.

```
User.where("(settings->>'opted_in')::boolean") # boolean query
User.where("settings->>'string_value' = ?", "some string") # string query 
```


## License

Licensed under the [MIT License](http://creativecommons.org/licenses/MIT)

Copyright 2015 [Mode Set](https://github.com/modeset)


## Make Code Not War
![crest](https://secure.gravatar.com/avatar/aa8ea677b07f626479fd280049b0e19f?s=75)
