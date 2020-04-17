require 'yaml'
require 'erb'
require_relative 'hash'

class ValuesManager
  class << self
    def arg_values(name)
      indicies = ARGV.each_index.select { |i| ARGV[i]==name }
      indicies.map { |key_index| ARGV[key_index + 1] }
    end

    def arg_value(name)
      key_index = ARGV.find_index(name)
      ARGV[key_index + 1] if key_index
    end

    def run_env
      arg_value('-e') || ENV['NECTAR_K8S_ENV'] || 'development'
    end

    def file_values(fname, helper)
      file = File.read(fname)
      helper_binding = helper.get_binding
      interpolated_yaml = ERB.new(file).result(helper_binding)
      YAML.load(interpolated_yaml)
    end

    def v_path(fname)
      "values/#{fname}.yaml.erb"
    end

    def load(helper)
      env_file = run_env && v_path(run_env)
      file_names = [v_path('values'), env_file, *arg_values('-f')].compact
      result = file_names.inject({}) do |merged, file_name|
        values = file_values(file_name, helper)
        merged.deep_merge(values)
      end
      result.symbolize_keys_deep
    end
  end
end