require 'yaml'
require 'active_support/core_ext/hash/keys'

module Kerb
  class Gen
    attr_reader :values

    def initialize(values)
      @values = values
    end

    def gen
      []
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
      return fname if File.exist?(fname)
      dir = self.class.get_location
      "#{dir}/#{fname}.yaml.erb"
    end

    def interpolate(fname, extras = {})
      file = File.read(resolve_file_name(fname))
      binding.local_variable_set(:extras, extras)
      ERB.new(file).result(binding)
    end

    def inflate(fname, extras: {}, only: nil, except: nil)
      interpolated_yaml = interpolate(fname, extras)
      hashes = YAML.load_stream(interpolated_yaml)
      hashes = hashes.map(&:deep_symbolize_keys)
      hashes = filter_res_only(hashes, Array(only))
      filter_res_except(hashes, Array(except))
    end

    def secrify(string)
      Base64.encode64(string)
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
end