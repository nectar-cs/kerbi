require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'base_helper'
require_relative 'utils'

module Kerbi
  class Gen
    include Kerbi::BaseHelper

    attr_reader :values

    def initialize(values)
      @values = values
    end

    def poly_gen(&block)
      bucket = Kerbi::Bucket.new(self)
      block.call(bucket)
      bucket.output.flatten
    end

    def gen
      raise 'Unimplemented'
    end

    def res_id(hash)
      kind = hash[:kind]
      name = hash[:metadata]&.[](:name)
      kind && name ? "#{kind}:#{name}" : ''
    end

    def filter_res_only(hashes, rules)
      return hashes if rules.compact.empty?
      hashes.select { |hash| rules.include?(res_id(hash)) }
    end

    def filter_res_except(hashes, rules)
      return hashes if rules.compact.empty?
      hashes.reject { |hash| rules.include?(res_id(hash)) }
    end

    def resolve_file_name(fname)
      dir = self.class.get_location
      Kerbi::Utils.try_paths(
        fname,
        "#{fname}.yaml",
        "#{fname}.yaml.erb",
        "#{dir}/#{fname}",
        "#{dir}/#{fname}.yaml",
        "#{dir}/#{fname}.yaml.erb",
      )
    end

    def interpolate(fname, extras = {})
      file_path = resolve_file_name(fname)
      raise "Could not resolve for #{fname}" unless file_path
      file = File.read(file_path)
      binding.local_variable_set(:extras, extras)
      ERB.new(file).result(binding)
    end

    def process(hashes, only, except)
      hashes = hashes.map(&:deep_symbolize_keys)
      hashes = filter_res_only(hashes, Array(only))
      filter_res_except(hashes, Array(except))
    end

    def inflate_yaml(fname, extras: {}, only: nil, except: nil)
      interpolated_yaml = interpolate(fname, extras)
      hashes = YAML.load_stream(interpolated_yaml)
      process(hashes, only, except)
    end

    class << self
      def locate_self(val)
        @dir_location = val
      end

      def get_location
        @dir_location
      end
    end
  end

  class Bucket
    attr_reader :output
    attr_reader :parent

    def initialize(parent)
      @parent = parent
      @output = []
    end

    def yaml(*args)
      output << parent.inflate_yaml(*args)
    end

    def hash(hash, *args)
      hash = [hash] unless hash.is_a?(Array)
      output << parent.process(hash, args[1], args[2])
    end

    def method_missing(method, *args)
      parent.send(method, *args) if parent.respond_to?(method)
      super
    end
  end
end