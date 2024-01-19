# frozen_string_literal: true

require_relative "lib/dry_module_generator/version"

Gem::Specification.new do |spec|
  spec.name = "dry_module_generator"
  spec.version = DryModuleGenerator::VERSION
  spec.authors = ["Jane-Terziev"]
  spec.email = ["janeterziev@gmail.com"]

  spec.summary = "A custom generator for creating features as modules using the dry.rb gems"
  spec.description = "A custom generator for creating features as modules using the dry.rb gems. The module registers a
dry system provider, adds routes, view and migrations paths to the application configuration and registers the models
and services for dependency injection."
  spec.homepage = "https://github.com/Jane-Terziev/dry_module_generator"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Jane-Terziev/dry_module_generator"
  spec.metadata["changelog_uri"] = "https://github.com/Jane-Terziev/dry_module_generator"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_development_dependency "dry_object_mapper"
  spec.add_development_dependency "dry-struct"
  spec.add_development_dependency "dry_struct_generator"
  spec.add_development_dependency "dry-validation"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "railties"
end
