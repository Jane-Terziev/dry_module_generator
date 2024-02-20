# frozen_string_literal: true

module DryModuleGenerator
  class Generator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)
    namespace "dry_module"

    argument :module_name, type: :string, required: false
    class_option :class_name, type: :string, default: nil
    class_option :attributes, type: :hash, default: {}
    class_option :response_format, type: :string, default: "html"

    TYPE_TO_DRY_TYPE = {
      'array': "Types::Array",
      'boolean': "Types::Bool",
      'date': "Types::Date",
      'datetime': "Types::DateTime",
      'float': "Types::Float",
      'integer': "Types::Integer",
      'string': "Types::String",
      'time': "Types::Time"
    }.freeze

    TYPE_TO_FORM_FIELD = {
      'string': "text_field_tag",
      'date': "date_field_tag",
      'time': "time_field_tag",
      'datetime': "datetime_field_tag",
      'integer': "number_field_tag",
      'float': "text_field_tag",
      'boolean': "check_box_tag"
    }.freeze

    attr_accessor :config

    def initialize(args, *options)
      super
      self.module_name = args[0]
      self.config = Config::GeneratorConfiguration
    end

    def create_app
      template("app/service.rb", File.join("#{module_path}/app/#{class_name.downcase}_service.rb"))
      template("app/read_service/service.rb",
               File.join("#{module_path}/app/read_service/#{class_name.downcase}_service.rb"))
      template(
        "app/read_service/get_list_dto.rb",
        File.join("#{module_path}/app/read_service/get_#{class_name.pluralize.downcase}_list_dto.rb")
      )
      template(
        "app/read_service/get_details_dto.rb",
        File.join("#{module_path}/app/read_service/get_#{class_name.downcase}_details_dto.rb")
      )
    end

    def create_domain
      template("domain/model.rb", File.join("#{module_path}/domain/#{class_name.downcase}.rb"))
      template(
        "domain/events/created_event.rb",
        File.join("#{module_path}/domain/#{class_name.downcase}/created_event.rb")
      )
      template(
        "domain/events/updated_event.rb",
        File.join("#{module_path}/domain/#{class_name.downcase}/updated_event.rb")
      )
      template(
        "domain/events/deleted_event.rb",
        File.join("#{module_path}/domain/#{class_name.downcase}/deleted_event.rb")
      )
    end

    def create_infra
      template("infra/system/provider_source.rb", File.join("#{module_path}/infra/system/provider_source.rb"))
      @timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      template(
        "infra/db/migrate/migration.rb",
        File.join(
          "#{module_path}/infra/db/migrate/#{@timestamp}_create_#{class_name.downcase.pluralize}.rb"
        )
      )
      template("infra/config/application.rb", File.join("#{module_path}/infra/config/application.rb"))
      template("infra/config/routes.rb", File.join("#{module_path}/infra/config/routes.rb"))
      template("infra/config/importmap.rb", File.join("#{module_path}/infra/config/importmap.rb"))
    end

    def create_ui
      template("ui/create_validation.rb", File.join("#{module_path}/ui/create_#{class_name.downcase}_validator.rb"))
      template("ui/update_validation.rb", File.join("#{module_path}/ui/update_#{class_name.downcase}_validator.rb"))
      template("ui/controller.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}_controller.rb"))
      empty_directory("#{module_path}/ui/javascript/controllers") if Config::GeneratorConfiguration.include_views
    end

    def create_views
      return unless Config::GeneratorConfiguration.include_views

      template_path = "ui/views/#{config.css_framework}/#{config.html_style}"
      template("#{template_path}/_form.html.erb",
               File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/_form.html.erb"))
      template("#{template_path}/_table_filter.html.erb",
               File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/_table_filter.html.erb"))
      template("#{template_path}/index.html.erb",
               File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/index.html.erb"))
      template("#{template_path}/show.html.erb",
               File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/show.html.erb"))
      template("#{template_path}/new.html.erb",
               File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/new.html.erb"))
      template("#{template_path}/edit.html.erb",
               File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/edit.html.erb"))
    end

    def add_importmap_configuration
      return unless Config::GeneratorConfiguration.include_views

      append_to_file("app/assets/config/manifest.js") do
        "//= link_tree ../../../#{module_name}/lib/#{module_name}/ui/javascript/controllers .js"
      end

      append_to_file("app/javascript/controllers/index.js") do
        "eagerLoadControllersFrom('#{module_name}', application)"
      end
    end

    def create_tests
      template(
        "spec/app/service_spec.rb",
        File.join("#{module_name}/spec/app/#{class_name.downcase}_service_spec.rb")
      )
      template(
        "spec/app/read_service/service_spec.rb",
        File.join("#{module_name}/spec/app/read_service/#{class_name.downcase}_service_spec.rb")
      )
      template(
        "spec/domain/model_spec.rb",
        File.join("#{module_name}/spec/domain/#{class_name.downcase}_spec.rb")
      )
      template(
        "spec/ui/controller_spec.rb",
        File.join("#{module_name}/spec/ui/#{class_name.pluralize.downcase}_controller_spec.rb")
      )
      @action_type = "Create"
      template(
        "spec/ui/validation_spec.rb",
        File.join("#{module_name}/spec/ui/create_#{class_name.downcase}_validator_spec.rb")
      )
      @action_type = "Update"
      template(
        "spec/ui/validation_spec.rb",
        File.join("#{module_name}/spec/ui/update_#{class_name.downcase}_validator_spec.rb")
      )
    end

    private

    def module_path
      "#{module_name}/lib/#{module_name}"
    end

    def class_name
      options[:class_name]&.singularize&.capitalize || file_name.singularize.capitalize
    end

    def contract_definition
      d = []
      options[:attributes].each do |field_name, value|
        type, necessity = value.split(":")
        necessity ||= "required"
        nullable = necessity == "required" ? "value" : "maybe"
        definition = "#{necessity}(:#{field_name}).#{nullable}(:#{type}"
        definition = necessity == "required" ? "#{definition}, :filled?)" : "#{definition})"
        d << definition
      end

      d
    end

    def dto_definition
      d = []
      options[:attributes].each do |field_name, value|
        type, necessity = value.split(":")
        necessity ||= "required"
        nullable = necessity == "required" ? "attribute" : "attribute?"

        d << "#{nullable} :#{field_name}, #{TYPE_TO_DRY_TYPE[type.to_sym]}"
      end

      d
    end

    def contract_test_params
      params = []
      test_data = {
        'array': "[]",
        'boolean': "true",
        'date': "Date.today",
        'datetime': "DateTime.now",
        'float': "0.1",
        'integer': "1",
        'string': "'string'",
        'time': "Time.now"
      }
      options[:attributes].each do |field_name, value|
        type, necessity = value.split(":")
        required = necessity == "required"
        params << {
          field_name: field_name,
          value: test_data[type.to_sym],
          required: required
        }
      end

      params
    end

    def migration_definition
      d = []
      options[:attributes].each do |field_name, value|
        type = value.split(":").first
        d << "t.#{type} :#{field_name}"
      end
      d
    end

    def form_attributes
      d = []
      options[:attributes].each do |field_name, value|
        type, necessity = value.split(":")
        required = necessity == "required"
        d << { field_name: field_name, type: TYPE_TO_FORM_FIELD[type.to_sym], label: field_name.capitalize,
               required: required }
      end

      d
    end
  end
end
