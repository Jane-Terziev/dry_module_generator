# frozen_string_literal: true

module DryModuleGenerator
  class Generator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)
    namespace "dry_module"

    argument :module_name, type: :string, required: false
    class_option :class_name, type: :string, default: nil
    class_option :attributes, type: :hash, default: {}

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

    def initialize(args, *options)
      super
      self.module_name = args[0]
    end

    def create_app
      template("app/service.rb", File.join("#{module_path}/app/#{class_name.downcase}_service.rb"))
      template("app/list_dto.rb", File.join("#{module_path}/app/get_#{class_name.pluralize.downcase}_list_dto.rb"))
      template("app/details_dto.rb", File.join("#{module_path}/app/get_#{class_name.downcase}_details_dto.rb"))
    end

    def create_domain
      template("domain/model.rb", File.join("#{module_path}/domain/#{class_name.downcase}.rb"))
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
    end

    def create_ui
      @action_type = "Create"
      template("ui/validation.rb", File.join("#{module_path}/ui/create_#{class_name.downcase}_validator.rb"))
      @action_type = "Update"
      template("ui/validation.rb", File.join("#{module_path}/ui/update_#{class_name.downcase}_validator.rb"))
      template("ui/controller.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}_controller.rb"))
    end

    def create_views
      template("ui/views/form.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/_form.html.erb"))
      template("ui/views/index.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/index.html.erb"))
      template("ui/views/show.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/show.html.erb"))
      template("ui/views/new.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/new.html.erb"))
      template("ui/views/edit.rb", File.join("#{module_path}/ui/#{class_name.pluralize.downcase}/edit.html.erb"))
    end

    def create_tests
      @action_type = "Create"
      template(
        "spec/ui/validation_test.rb",
        File.join("#{module_name}/spec/ui/create_#{class_name.downcase}_validator_spec.rb")
      )
      @action_type = "Update"
      template(
        "spec/ui/validation_test.rb",
        File.join("#{module_name}/spec/ui/update_#{class_name.downcase}_validator_spec.rb")
      )
      template("spec/app/service_test.rb", File.join("#{module_name}/spec/app/#{class_name.downcase}_service_spec.rb"))
      template("spec/ui/controller_test.rb", File.join("#{module_name}/spec/ui/#{class_name.pluralize.downcase}_controller_spec.rb"))
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
