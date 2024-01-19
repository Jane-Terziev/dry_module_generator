# frozen_string_literal: true

require_relative "dry_module_generator/version"
require "rails/generators"
require_relative "dry_module_generator/module/generator"

module DryModuleGenerator
  class Error < StandardError; end
  # Your code goes here...
end
