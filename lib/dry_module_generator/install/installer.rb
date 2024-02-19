# frozen_string_literal: true

module DryModuleGenerator
  class Installer < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    namespace "dry_module:install"

    def create_utility_files
      full_file_paths = Dir.glob(File.join(self.class.source_root, '**', '**')).filter {|it| it.include?('.rb.tt') }
      file_names = full_file_paths.map {|it| it.split('templates/').last.chop.chop.chop }
      file_names.each {|name| template(name, File.join(name)) }
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
        "  include Import.inject[validator: 'contract_validator']"
      end
    end

    def update_application_helper
      file_path = "app/helpers/application_helper.rb"
      file_content = File.read(file_path)

      unless file_content.include?("def show_error")
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

      unless file_content.include?("include Pagy::Frontend")
        inject_into_module file_path, "ApplicationHelper" do
          "  include Pagy::Frontend

"
        end
      end
    end

    def update_gemfile
      file_path = "Gemfile"
      file_content = File.read(file_path)

      append_to_file(file_path) do
        "
gem 'sass-rails'"
      end unless file_content.include?('sass-rails')

      append_to_file(file_path) do
        "
gem 'dry-validation'"
      end unless file_content.include?('dry-validation')

      append_to_file(file_path) do
        "
gem 'dry-struct'"
      end unless file_content.include?('dry-struct')

      append_to_file(file_path) do
        "
gem 'dry-system', '~> 1'"
      end unless file_content.include?('dry-system')

      append_to_file(file_path) do
        "
gem 'dry_struct_generator'"
      end unless file_content.include?('dry_struct_generator')

      append_to_file(file_path) do
        "
gem 'dry_object_mapper'"
      end unless file_content.include?('dry_object_mapper')

      append_to_file(file_path) do
        "
gem 'pagy'"
      end unless file_content.include?('pagy')

      append_to_file(file_path) do
        "
gem 'ransack'"
      end unless file_content.include?('ransack')

      append_to_file(file_path) do
        "
gem 'rails_event_store'"
      end unless file_content.include?('rails_event_store')
    end
  end
end
