require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/deep_merge'
require 'yaml'
require 'erb'

module Kerbi
  class ValMan
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

      def load(helper)
        puts "COMING IN WITH THE FOLLOWING ARGS"
        puts ARGV
        ARGV.each do a
          puts(a)
        end
        result = all_values_paths.inject({}) do |merged, file_name|
          values = read_values_file(file_name, helper)
          merged.deep_merge(values)
        end
        result.deep_symbolize_keys
      end
    end
  end
end