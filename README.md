# DryModuleGenerator

A custom generator for creating features as modules using the dry.rb gems. The module registers a dry system provider, 
adds routes, view and migrations paths to the application configuration and registers the models and services for 
dependency injection.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry_module_generator'
```

Intall the gem
    
    bundle install

Then run the setup generator which adds all the utilities and
configurations to your project:

    rails g dry_module:setup

## Usage
Run the following command in the terminal:

    rails g dry_module module_name 
    --attributes attribute1:string:required
    attribute2:integer:optional
    attribute3:boolean:optional

Separate your attributes with spaces.
The attributes are sent in the following format: attribute_name:type:(required/optional).

The supported attribute types are: string, integer, float, boolean, array, date, datetime, time.

This will generate a folder in your root path with the following structure:

    root
        module_name
          - lib
            - module_name
                - app
                    - service.rb
                    - list_dto.rb
                    - details_dto.rb
                - domain
                    - model.rb
                - infra
                    - config
                    - db
                        - migrations
                            - migration_file.rb
                    - system
                        - provider_source.rb
                - ui
                    - views
                        - _form.html.erb
                        - index.html.erb
                        - edit.html.erb
                        - show.html.erb
                        - new.html.erb
                    - create_validation.rb
                    - update_validation.rb
                    - controller.rb


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Jane-Terziev/dry_module_generator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/dry_module_generator/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DryModuleGenerator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/dry_module_generator/blob/master/CODE_OF_CONDUCT.md).
