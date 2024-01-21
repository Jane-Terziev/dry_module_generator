# frozen_string_literal: true

module DryModuleGenerator
  class Uninstaller < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    namespace "dry_module:uninstall"

    # causing class errors
    def remove_config_files
      remove_file "config/initializers/container.rb"
      remove_file "config/initializers/dependency_injection.rb"
      remove_file "config/initializers/dry_struct_generator.rb"
      remove_file "config/initializers/routes.rb"
    end

    def remove_utility_files
      remove_file "lib/utils/types.rb"
      remove_file "lib/utils/application_struct.rb"
      remove_file "lib/utils/application_read_struct.rb"
      remove_file "lib/utils/application_contract.rb"
      remove_file "lib/utils/contract_validator.rb"
      FileUtils.remove_dir("lib/utils/injection", force: true)
    end

    def remove_error_file
      remove_file "app/errors/constraint_error.rb"
    end

    def remove_service_file
      remove_file "app/services/application_service.rb"
    end
  end
end
