# frozen_string_literal: true

module DryModuleGenerator
  class Installer < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    namespace "dry_module:setup"

    def update_application_record
      file_path = "app/models/application_record.rb"
      class_name = "ApplicationRecord"

      # Read the existing content of the file
      file_content = File.read(file_path)

      # Define the code you want to add
      additional_code = "

  def self.save(record)
    record.tap(&:save)
  end

  def self.save!(record)
    record.tap(&:save!)
  end

  def self.delete!(record)
    record.tap(&:destroy!)
  end"

      # Check if the class is present in the file
      if file_content.include?("class #{class_name}") && !file_content.include?("def self.save!")
        # If the class is present, find the end of the class definition and add the code there
        class_definition_end = file_content.index("end", file_content.index("class #{class_name}"))
        if class_definition_end
          inject_code_position = class_definition_end - 1
          file_content.insert(inject_code_position, additional_code)
          File.write(file_path, file_content)
        else
          puts "Error: Unable to find the end of the class definition in #{file_path}."
        end
      else
        puts "Error: Unable to find the class definition for #{class_name} in #{file_path}."
      end
    end

    def create_utils
      template("utils/contract_validator.rb", File.join("lib/utils/contract_validator.rb"))
      template("utils/types.rb", File.join("lib/utils/types.rb"))
      template("utils/application_contract.rb", File.join("lib/utils/application_contract.rb"))
      template("utils/application_struct.rb", File.join("lib/utils/application_struct.rb"))
      template("utils/application_read_struct.rb", File.join("lib/utils/application_read_struct.rb"))
      template(
        "utils/injection/controller_resolve_strategy.rb",
        File.join("lib/utils/injection/controller_resolve_strategy.rb")
      )
    end

    def create_application_service
      template("services/application_service.rb", File.join("app/services/application_service.rb"))
    end

    def create_constraint_error
      template("errors/constraint_error.rb", File.join("app/errors/constraint_error.rb"))
    end

    def create_initializers
      template("initializers/container.rb", File.join("config/initializers/container.rb"))
      template("initializers/dependency_injection.rb", File.join("config/initializers/dependency_injection.rb"))
      template("initializers/dry_struct_generator.rb", File.join("config/initializers/dry_struct_generator.rb"))
      template("initializers/routes.rb", File.join("config/initializers/routes.rb"))
    end

    def update_application
      inject_into_file "config/application.rb" do
        "
Dir[File.join(Rails.root, '*', 'lib', '*', 'infra', 'config', 'application.rb')].each do |file|
  require File.join(File.dirname(file), File.basename(file, File.extname(file)))
end
        "
      end
    end

    def update_application_controller
      file_path = "app/controllers/application_controller.rb"
      file_content = File.read(file_path)

      return if file_content.include?("ConstraintError")

      inject_into_class file_path, "ApplicationController" do
        "  include Import.inject[validator: 'contract_validator']

  rescue_from(ConstraintError) do |e|
    @form = e.validator
    if action_name == 'create'
      render :new, status: :unprocessable_entity
    elsif action_name == 'update'
      render :edit, status: :unprocessable_entity
    end
  end

"
      end
    end

    def update_application_helper
      file_path = "app/helpers/application_helper.rb"
      file_content = File.read(file_path)

      return if file_content.include?("def show_error")

      inject_into_module file_path, "ApplicationHelper" do
        <<-"CODE"
  def show_error(validator, keys)
    return unless validator.errors
    keys = [keys] unless keys.is_a?(Array)
    field_name = keys.last
    if validator.errors.any?
      result = find_value(validator.errors, keys)
      return "\#{field_name.to_s.humanize} \#{result.join(', ')}" unless result.blank?
    end
  end

  def find_value(hash, keys)
    result = hash
    keys.each do |key|
      if result.is_a?(Hash) && result.key?(key)
        result = result[key]
      elsif result.is_a?(Array)
        result = result.map { |item| item.is_a?(Hash) ? item[key] : nil }.compact
        result = result.first if result.length == 1 # If there's only one element in the array
      else
        return nil
      end
    end
    result
  end

  def invalid?(validator, keys)
    if show_error(validator, keys)
      'invalid'
    else
      ''
    end
  end
        CODE
      end
    end

    def create_javascripts
      template("javascript/controllers/form_controller.js", File.join("app/javascript/controllers/form_controller.js"))
      template("javascript/controllers/drawer_controller.js", File.join("app/javascript/controllers/drawer_controller.js"))
      template("javascript/controllers/sidebar_controller.js", File.join("app/javascript/controllers/sidebar_controller.js"))
      template("javascript/controllers/theme_controller.js", File.join("app/javascript/controllers/theme_controller.js"))
    end

    def create_shared_views
      template("views/shared/_bottom_navigation.html.erb", File.join("app/views/shared/_bottom_navigation.html.erb"))
      template("views/shared/_navbar.html.erb", File.join("app/views/shared/_navbar.html.erb"))
      template("views/shared/_navigation_drawer.html.erb", File.join("app/views/shared/_navigation_drawer.html.erb"))
      template("views/shared/_sidebar.html.erb", File.join("app/views/shared/_sidebar.html.erb"))
    end

    def create_styles
      template("css/generator.scss", File.join("app/assets/stylesheets/generator.scss"))
    end

    def create_dry_setup_guide_folder
      %w[
        dry_setup_guide/Gemfile
        dry_setup_guide/config/application.rb
        dry_setup_guide/config/importmap.rb
        dry_setup_guide/app/assets/stylesheets/application.scss
        dry_setup_guide/app/javascript/application.js
        dry_setup_guide/app/views/layouts/application.html.erb
      ].each do |template_file|
        template(template_file, File.join(template_file))
      end
    end
  end
end
