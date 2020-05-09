require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/deep_merge'
require 'yaml'
require 'erb'

module Kerbi
  class ValMan
    class << self
      def str_assign_to_h(str_assign)
        key_expr, value = str_assign.split(":")
        assign_parts = key_expr.split(".") << value
        assign_parts.reverse.inject{ |a,n| { n=>a } }.deep_symbolize_keys
      end

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

      def values_paths(fname)
        [
          fname,
          "values/#{fname}",
          "values/#{fname}.yaml.erb",
          "values/#{fname}.yaml",
          "#{fname}.yaml.erb",
          "#{fname}.yaml",
        ]
      end

      def all_values_paths
        [
          *values_paths('values'),
          *values_paths(run_env),
          *arg_values('-f')
        ].compact
      end

      def read_values_file(fname, helper)
        file_cont = File.read(fname) rescue nil
        return {} unless file_cont
        file_cont = ERB.new(file_cont).result(helper.get_binding) if helper
        YAML.load(file_cont).deep_symbolize_keys
      end

      def read_arg_assignments
        str_assignments = arg_values("--set")
        str_assignments.inject({}) do |whole, str_assignment|
          whole.merge(str_assign_to_h(str_assignment))
        end
      end

      def load(helper)
        result = all_values_paths.inject({}) do |whole, file_name|
          whole.
            deep_merge(read_values_file(file_name, helper)).
            deep_merge(read_arg_assignments)
        end
        result.deep_symbolize_keys
      end
    end
  end
end