# SoftDelete

(Yet another) Soft delete active_record models.  

Why another soft delete?  Soft deleting is a relatively common pattern which lets you hide records instead of deleting them.  Some gems are heavy handed and override normal deleting.  Most of them make a lot of decisions or assumptions about how you will be soft deleting.  This gem takes an open approach and lets you decide how little or how much your project will be using the soft delete pattern.  It can be configured on a per-model level to use whichever features are appropriate at the time.  This makes it especially easy to introduce soft delete into existing projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ar_soft_delete'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ar_soft_delete

## Usage

SoftDelete works by setting `deleted_at` to Time.now.  Make sure your model has a datetime `deleted_at` column or if you want to use any other user defined column name for you model make sure to define it in initializer like below.

```ruby
# config/initializers/soft_delete.rb (for Rails app) or similar setup in any Ruby app
SoftDelete.configure do |config|
  config.target_column = :archived_at # user defined column name
end
```

Include the module into your active_record class:

```ruby
class Author < ApplicationRecord
  include SoftDelete::SoftDeletable

  ...
end
```

`myModel.soft_delete` returns `true|false`.

`myModel.soft_delete!` raises `ActiveRecord::RecordInvalid` on failure.

You can also pass an optional `validate: false` argument to ignore validations on save.  This can be useful if you want to soft delete a record that would normally not save because it is invalid.

Exa:

```ruby
foo.valid?
> false
foo.soft_delete(validate: false)
> true
```

## Dependency Behavior

In general, SoftDelete considers "soft deleting" and "normal deleting" to be two separate things.  Under this philosophy, SoftDelete's default behavior is to do as little as possible (just set the `deleted_at` column).  There are no callbacks fired off, associations are not updated, etc.

However, sometimes you want to handle soft deletes as if they are real deletes.  To that end, SoftDelete allows you to set a dependency behavior
`include SoftDelete::SoftDeletable.dependent(:ignore|:default|:soft_delete)`
* `:ignore`: The default.  Do nothing with associated records.  Useful if you want to soft delete specific records with no other side effects.  Example use case:
I have identified bad data.  I want to be able to delete the data, see the ramifications and potentially quickly restore the data if the delete was a mistake.
* `:default`: Fire off the same action that is described by the active_record dsl in the model.  Exa (`has_many :enemies, default: :destroy`) would destroy the enemies when the model is soft deleted.  This is useful if you are incrementally adding soft delete to certain models and want the rest of the behavior to remain the same.
* `:soft_delete`: overrides the `:destroy` association option to invoke a `soft_delete` on the associated records.  This comes the closest to automatically replacing normal deletes with soft deletes.  It runs before|around|after destroy hooks when it soft deletes.

Exa:

```ruby
class Author < ApplicationRecord
  include SoftDelete::SoftDeletable.dependent(:soft_delete)

  has_many :notes, dependent: :destroy
  ...
end
```

However if you still feel like skipping soft delete over certain associations, you can acheive so by passing an array of skipping Model Names to dependent soft delete for example:

```ruby
class Author < ApplicationRecord
  include SoftDelete::SoftDeletable.dependent(:soft_delete, skip_dependent_soft_delete: ['Publisher'])

  has_many :notes, dependent: :destroy
  has_many :publishers, dependent: :destroy
  ...
end
```

In the above example Notes would be soft deleted but publishers would be skipped to be soft deleted.

## Default Scope

By default, SoftDelete uses a default_scope.  Do you feel strongly that a default scope is not for you?  SoftDelete can be included without a default scope:
`include SoftDelete::SoftDeletable.not_scoped`

This will skip adding a default scope to the model and instead will add an `active` scope that you can use to filter the records.

Reminder: You can chain the scope and dependency options!

```ruby
class Author < ApplicationRecord
  include SoftDelete::SoftDeletable.not_scoped.dependent(:default)

  has_many :notes, dependent: :destroy
end
```

## SoftDelete Restorable

You can also include the `SoftDelete::Restorable` module to include a `deleted` scope which overrides the default `deleted_at` scope if it exists.

```ruby
class Note < ApplicationRecord
  include SoftDelete::Restorable
  ...
end

Note.deleted # returns records that have been soft deleted
```

It also mixes in `restore_soft_delete` and `restore_soft_delete!`.  They both can take an optional `validate` param to restore an otherwise invalid record.

exa:
```ruby
note = Note.deleted.find_by(id: 2)
note.valid?
> false
note.restore_soft_delete(validate: false)
> true
```

## Caveats

SoftDelete uses a class var to hold the dependency behavior.  This has implications if you subclass a model that includes SoftDelete.  All subclasses share the same class variable and therefore would share the same soft delete dependency behavior.  Changing it in a subclass changes it for the ancestors as well as any children.

SoftDelete does not currently support updating cache counters when a record is soft deleted.

## Roadmap

* before|after soft_delete hooks.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/swelltrain/soft_delete.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
