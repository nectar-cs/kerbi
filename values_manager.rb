require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/deep_merge'
require 'yaml'
require 'erb'

class ValuesManager
  class << self
    def arg_values(name)
      indicies = ARGV.each_index.select { |i| ARGV[i]==name }
      indicies.map { |key_index| ARGV[key_index + 1] }
    end

    def arg_value(name)
      self.arg_values(name)&.first
    end

    def run_env
      arg_value('-e') || ENV['NECTAR_K8S_ENV'] || 'development'
    end

    def v_path(fname)
      "values/#{fname}.yaml.erb"
    end

    def file_values(fname, helper)
      file = File.read(fname)
      helper_binding = helper.get_binding
      interpolated_yaml = ERB.new(file).result(helper_binding)
      YAML.load(interpolated_yaml).deep_symbolize_keys
    end

    def load(helper)
      env_file = run_env && v_path(run_env)
      file_names = [v_path('values'), env_file, *arg_values('-f')].compact
      result = file_names.inject({}) do |merged, file_name|
        values = file_values(file_name, helper)
        merged.deep_merge(values)
      end
      result.deep_symbolize_keys
    end
  end
end