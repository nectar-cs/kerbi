require_relative './mixer_helper'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/object/blank'
require 'yaml'
require 'json'
require 'erb'

module Kerbi
  class ValuesManager
    class << self
      def str_assign_to_h(str_assign)
        key_expr, value = str_assign.split("=")
        assign_parts = key_expr.split(".") << value
        assignment = assign_parts.reverse.inject{ |a,n| { n=>a } }
        assignment.deep_symbolize_keys
      end

      def file_assign_to_h(str_assign)
        key_expr, fname = str_assign.split("=")
        file_contents = File.read(fname)
        str_assign_to_h("#{key_expr}=#{file_contents}")
      end

      def arg_values(name)
        indicies = ARGV.each_index.select { |i| ARGV[i]==name }
        indicies.map { |key_index| ARGV[key_index + 1] }
      end

      def arg_value(name)
        self.arg_values(name)&.first
      end

      def run_env
        arg_value('-e') || ENV['KERBI_ENV'] || 'development'
      end

      def values_paths(fname)
        [
          fname,
          "values/#{fname}",
          "values/#{fname}.yaml.erb",
          "values/#{fname}.yaml",
          "values/#{fname}.json",
          "#{fname}.yaml.erb",
          "#{fname}.yaml",
          "#{fname}.json",
        ]
      end

      def all_values_paths
        [
          *values_paths('values'),
          *values_paths(run_env),
          *arg_values('-f')
        ].compact
      end

      def safely_read_values_file(name)
        candidate_fnames = values_paths(name)
        decider = -> (fname) { File.exists?(fname) }
        if (fname = candidate_fnames.find(&decider))
          read_values_file(fname)
        end
      end

      #noinspection RubyResolve
      def read_values_file(fname)
        file_cont = File.read(fname) rescue nil
        return {} unless file_cont
        load_json(file_cont) || load_yaml(file_cont) || {}
      end

      def load_yaml(file_cont)
        interpolated = Wrapper.new.interpolate(file_cont)
        YAML.load(interpolated).deep_symbolize_keys# rescue nil
      end

      def load_json(file_cont)
        JSON.parse(file_cont.deep_symbolize_keys) rescue nil
      end

      def read_arg_assignments
        str_assignments = arg_values("--set")
        str_assignments.inject({}) do |whole, str_assignment|
          assignment = str_assign_to_h(str_assignment)
          whole.deep_merge(assignment)
        end
      end

      def read_arg_file_assignments
        str_assignments = arg_values("--set-from-file")
        str_assignments.inject({}) do |whole, file_assignment|
          assignment = file_assign_to_h(file_assignment)
          whole.deep_merge(assignment)
        end
      end

      def read_release_name
        if ARGV[0] == 'template'
          ARGV[1]
        end
      end

      def load
        result = all_values_paths.inject({}) do |whole, file_name|
          whole.
            deep_merge(read_values_file(file_name)).
            deep_merge(read_arg_assignments).
            deep_merge(read_arg_file_assignments)
        end
        $release_name = read_release_name
        result.deep_symbolize_keys
      end
    end
  end
end

class Wrapper
  include Kerbi::MixerHelper

  def interpolate(file_cont)
    ERB.new(file_cont).result(binding)
  end
end
