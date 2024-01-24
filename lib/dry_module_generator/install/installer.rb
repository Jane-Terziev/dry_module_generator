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
      template("utils/pagination_dto.rb", File.join("lib/utils/pagination_dto.rb"))
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
      append_to_file "config/application.rb" do
        "
Dir[File.join(Rails.root, '*', 'lib', '*', 'infra', 'config', 'application.rb')].each do |file|
  require File.join(File.dirname(file), File.basename(file, File.extname(file)))
end
        "
      end

      inject_into_class "config/application.rb", 'Application' do
        '    config.eager_load_paths << Rails.root.join("lib/utils")
'
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

    def create_javascripts
      template("javascript/controllers/form_controller.js", File.join("app/javascript/controllers/form_controller.js"))
      template("javascript/controllers/drawer_controller.js", File.join("app/javascript/controllers/drawer_controller.js"))
      template("javascript/controllers/sidebar_controller.js", File.join("app/javascript/controllers/sidebar_controller.js"))
      template("javascript/controllers/theme_controller.js", File.join("app/javascript/controllers/theme_controller.js"))
      template("javascript/controllers/flash_controller.js", File.join("app/javascript/controllers/flash_controller.js"))
      template("javascript/toast.js", File.join("app/javascript/toast.js"))
      template("javascript/toastify-js.js", File.join("vendor/javascript/toastify-js.js"))
    end

    def create_shared_views
      template("views/shared/_bottom_navigation.html.erb", File.join("app/views/shared/_bottom_navigation.html.erb"))
      template("views/shared/_navbar.html.erb", File.join("app/views/shared/_navbar.html.erb"))
      template("views/shared/_navigation_drawer.html.erb", File.join("app/views/shared/_navigation_drawer.html.erb"))
      template("views/shared/_sidebar.html.erb", File.join("app/views/shared/_sidebar.html.erb"))
      template("views/shared/_flash.html.erb", File.join("app/views/shared/_flash.html.erb"))
      template("views/shared/_pagination.html.erb", File.join("app/views/shared/_pagination.html.erb"))
    end

    def create_styles
      template("css/generator.scss", File.join("app/assets/stylesheets/generator.scss"))
    end

    def update_application_stylesheet
      file_path = "app/assets/stylesheets/application.scss"

      unless File.exist?(file_path)
        File.rename("app/assets/stylesheets/application.css", file_path)
      end

      file_content = File.read(file_path)

      return if file_content.include?("generator")
      append_to_file(file_path) do
        "@import 'generator';"
      end
    end

    def update_application_javascript
      file_path = "app/javascript/application.js"
      file_content = File.read(file_path)

      unless file_content.include?("beercss")
        append_to_file(file_path) do
          "
import 'beercss';"
        end
      end

      unless file_content.include?("toast")
        append_to_file(file_path) do
          "
import { showToastMessage } from './toast';
window.showToastMessage = showToastMessage;"
        end
      end
    end

    def update_body_tag
      file_path = "app/views/layouts/application.html.erb"
      file_content = File.read(file_path)

      if file_content.include?("<body>")
        body_tag_index = file_content.index("<body>")
        body_end_tag_index = file_content.index("</body>")
        if body_tag_index
          file_content[body_tag_index..body_end_tag_index+6] = "
  <body data-controller='theme'>
    <%= render 'shared/sidebar', dialog: false, id: 'sidebar' %>
    <%= render 'shared/navigation_drawer' %>
    <%= render 'shared/bottom_navigation' %>
    <main class='responsive max'>
      <%= render 'shared/navbar' %>
      <div class='medium-margin'>
        <%= yield %>
      </div>
    </main>
  </body>"
          File.write(file_path, file_content)
        else
          puts "Error: Unable to body."
        end
      else
        puts "Error: Unable to body."
      end
    end

    def update_stylesheet
      file_path = "app/views/layouts/application.html.erb"
      file_content = File.read(file_path)
      # Check if the class is present in the file
      style_link_tag_index = file_content.index("stylesheet_link_tag")

      unless style_link_tag_index
        puts "Cannot find stylesheet link tag"
        return
      end

      inject_code_position = style_link_tag_index - 4

      unless file_content.include?("beercss")
        file_content.insert(inject_code_position, '
    <link href="https://cdn.jsdelivr.net/npm/beercss@3.4.13/dist/cdn/beer.min.css" rel="stylesheet" data-turbo-track="reload">
    ')
        File.write(file_path, file_content)
      end

      unless file_content.include?("toastify")
        if style_link_tag_index
          file_content.insert(inject_code_position, '
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/toastify-js/src/toastify.min.css">
          ')
          File.write(file_path, file_content)
        end
      end
    end

    def update_meta_tag
      file_path = "app/views/layouts/application.html.erb"
      file_content = File.read(file_path)
      unless file_content.include?("turbo-cache-control")
        title_tag = file_content.index("</title>")
        if title_tag
          inject_code_position = title_tag + 8
          file_content.insert(inject_code_position, '
    <meta name="turbo-cache-control" content="no-cache">
')
          File.write(file_path, file_content)
        else
          puts "Error: Unable to find title for meta tag"
        end
      end
    end

    def update_importmap_pin
      file_path = "config/importmap.rb"
      file_content = File.read(file_path)

      unless file_content.include?("beercss")
        append_to_file(file_path) do
          "
pin 'beercss', to: 'https://cdn.jsdelivr.net/npm/beercss@3.4.13/dist/cdn/beer.min.js'"
        end
      end

      unless file_content.include?("toastify")
        append_to_file(file_path) do
          "
pin 'toastify-js' # @1.12.0"
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
    end
  end
end
