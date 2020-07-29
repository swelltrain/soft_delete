# SoftDelete

Soft delete active_record models.  Currently a WIP and not a released gem :)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'soft_delete'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install soft_delete

## Usage

SoftDelete works by setting `deleted_at` to Time.now.  Make sure your model has a `deleted_at` column.  And include the module into your active_record class:

`include SoftDelete::SoftDeletable`

`myModel.soft_delete` returns `true|false`

`myModel.soft_delete!` raises `ActiveRecord::RecordInvalid` on failure

You can also pass an optional `validate: false` argument to ignore validations on save.  This can be useful if you want to soft delete a record that is normally invalid.

In general, SoftDelete considers "soft deleting" and "normal deleting" to be two separate things.  Under this philosophy, SoftDelete's default behavior is to do as little as possible (just set the `deleted_at` column).  There are no callbacks fired off, associations are not updated, etc.

However, sometimes you want to handle soft deletes as if they are real deletes.  To that end, SoftDelete allows you to set a dependency behavior
`include SoftDelete::SoftDeletable.dependent(:ignore|:default|:soft_delete)`
* `:ignore`: The default.  Do nothing with associated records.
* `:default`: Fire off the same action that is described by the active_record dsl in the model.  Exa (`has_many :enemies, default: :destroy`) would destroy the enemies when the model is soft deleted.
* `:soft_delete`: overrides the `:destroy` association option to invoke a `soft_delete` on the associated records.  This comes the closest to automatically replacing normal deletes with soft deletes.  Note: this feature is currently incomplete in that the normal object lifecycle callbacks are not invoked.

Caveats:
SoftDelete uses a default_scope.

SoftDelete uses a class var to hold the dependency behavior.  This has implications if you subclass.  All subclasses share the same class variable.

On the roadmap:
* More specs.
* Complete the `soft_delete` feature to invoke AR callbacks.
* Allow soft_delete feature to check if soft_delete is supported on associated model.  If not, let it fallback to destroy.
* `SoftDelete::Recoverable` for completeness.
* (Maybe?) allow the module to be included where it does not set a default scope.
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/soft_delete.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
