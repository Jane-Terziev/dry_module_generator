# frozen_string_literal: true

require_relative "dry_module_generator/version"
require "rails/generators"
require_relative "dry_module_generator/install/installer"
require_relative "dry_module_generator/module/generator"
require_relative "dry_module_generator/config/configuration"
require_relative "dry_module_generator/config/generator_configuration"

module DryModuleGenerator
  class Error < StandardError; end
  class ConfigurationError < StandardError; end
end
