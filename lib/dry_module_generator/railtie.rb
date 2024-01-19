# frozen_string_literal: true

require "rails"

module DryModuleGenerator
  class Railtie < Rails::Railtie
    config.generators do |generators|
      generators.templates.unshift File.expand_path("lib/dry_module_generator/module", __dir__)
      generators.templates.unshift File.expand_path("lib/dry_module_generator/install", __dir__)
    end
  end
end
