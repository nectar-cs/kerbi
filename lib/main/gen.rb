require 'yaml'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'
require_relative './base_helper'
require_relative './../utils/utils'

module Kerbi
  class Gen
    include Kerbi::BaseHelper

    attr_reader :values

    # Initializes with a Gen
    #
    # @param [Hash, #read] contents the contents to reverse
    # @return [String] the contents reversed lexically
    def initialize(values)
      @values = values
    end

    ##
    # Where users should return a hash or
    # an array of hashes representing Kubernetes resources
    #
    # @yield [bucket] Description of block
    # @return [[Hash]] array of hashes representing Kubernetes resources
    def gen(&block)
      if block_given?
        safe_gen(&block)
      end
    end

    def resolve_file_name(fname)
      dir = self.class.get_location
      Kerbi::Utils.real_files_for(
        fname,
        "#{fname}.yaml",
        "#{fname}.yaml.erb",
        "#{dir}/#{fname}",
        "#{dir}/#{fname}.yaml",
        "#{dir}/#{fname}.yaml.erb"
      ).first
    end

    def yamls_in_dir(dir=nil, blacklist=nil)
      dir ||= this_dir
      blacklist ||= []

      dir = "#{this_dir}/#{dir}" if dir.start_with?(".")
      yaml_files = Dir["#{dir}/*.yaml"]
      erb_files = Dir["#{dir}/*.yaml.erb"]

      (yaml_files + erb_files).map do |fname|
        is_blacklisted = blacklist.include?(File.basename(fname))
        inflate_yaml(fname) unless is_blacklisted
      end.compact
    end

    def interpolate(fname, extras = {})
      file = File.read(resolve_file_name(fname))
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

    def this_dir
      self.class.get_location
    end

    class << self
      def locate_self(val)
        @dir_location = val
      end

      def get_location
        @dir_location
      end
    end

    private

    def safe_gen(&block)
      bucket = Kerbi::Bucket.new(self)
      block.call(bucket)
      bucket.output.flatten
    end

    ##
    # @param[Hash, #hash] contents asd
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
  end

  class Bucket
    attr_accessor :output
    attr_accessor :parent

    def initialize(parent)
      @parent = parent
      @output = []
    end

    def patched_with(opts={}, &block)
      bucket = Kerbi::Bucket.new(self.parent)
      block.call(bucket)

      hashes = opts[:hashes] || [opts[:hash]]
      dir_patches = opts.has_key?(:yamls_in) && self.parent.yamls_in_dir(opts[:yamls_in])
      file_patches = (opts[:yamls] || []).map { |f| parent.inflate_yaml(f) }
      patches = (hashes + file_patches + (dir_patches || [])).flatten.compact

      self.output = bucket.output.flatten.map do |res|
        patches.inject(res) do |whole, patch|
          whole.deep_merge(patch)
        end
      end
    end

    def yamls(options={})
      dir, blacklist = options.slice(:in, :except).values
      self.output += self.parent.yamls_in_dir(dir, [blacklist].compact)
    end

    def yaml(*args)
      self.output << parent.inflate_yaml(*args)
    end

    def hash(hash, *args)
      hash = [hash] unless hash.is_a?(Array)
      self.output << parent.process(hash, args[1], args[2])
    end

    def method_missing(method, *args)
      parent.send(method, *args) if parent.respond_to?(method)
      super
    end
  end
end