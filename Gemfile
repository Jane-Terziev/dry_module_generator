# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in dry_module_generator.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"

# For validating user input
gem 'dry-validation'
# Data Transfer Objects
gem 'dry-struct'
# Container and Dependency Injection
gem 'dry-system', '~> 1'
# Convert your Dry::Validation::Contract schemas into Dry::Struct objects and send them in your services
gem 'dry_struct_generator'
# Mapper for turning our ActiveRecord objects into response DTO objects to avoid triggering queries inside the
# presentation layer of our application
gem 'dry_object_mapper'