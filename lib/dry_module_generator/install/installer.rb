# frozen_string_literal: true

module DryModuleGenerator
  class Installer < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    namespace "dry_module:setup"

    def update_application_record
      file_path = 'app/models/application_record.rb'
      class_name = 'ApplicationRecord'

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
      template('utils/contract_validator.rb', File.join("lib/utils/contract_validator.rb"))
      template('utils/types.rb', File.join("lib/utils/types.rb"))
      template('utils/application_contract.rb', File.join("lib/utils/application_contract.rb"))
      template('utils/application_struct.rb', File.join("lib/utils/application_struct.rb"))
      template('utils/application_read_struct.rb', File.join("lib/utils/application_read_struct.rb"))
      template(
        'utils/injection/controller_resolve_strategy.rb',
        File.join("lib/utils/injection/controller_resolve_strategy.rb")
      )
    end

    def create_application_service
      template('services/application_service.rb', File.join("app/services/application_service.rb"))
    end

    def create_constraint_error
      template('errors/constraint_error.rb', File.join("app/errors/constraint_error.rb"))
    end

    def create_initializers
      template('initializers/container.rb', File.join("config/initializers/container.rb"))
      template('initializers/dependency_injection.rb', File.join("config/initializers/dependency_injection.rb"))
      template('initializers/dry_struct_generator.rb', File.join("config/initializers/dry_struct_generator.rb"))
      template('initializers/routes.rb', File.join("config/initializers/routes.rb"))
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
  end
end
