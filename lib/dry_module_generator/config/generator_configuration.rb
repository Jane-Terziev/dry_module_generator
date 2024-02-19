# frozen_string_literal: true

module DryModuleGenerator
  module Config
    module GeneratorConfiguration
      extend Configuration

      define_setting :include_views, true
      define_setting :css_framework, "bootstrap5"
      define_setting :html_style, "erb"
    end
  end
end