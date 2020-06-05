require 'yaml'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'
require_relative './base_helper'
require_relative './../utils/utils'
require_relative './bucket'

module Kerbi
  class Gen
    include Kerbi::BaseHelper

    ##
    # Values hash available to subclasses
    # @return [Hash] symbol-keyed hash
    attr_reader :values

    ##
    # Constructor
    # @param [Hash] values the values tree that will be accessible to the subclass
    def initialize(values)
      @values = values
    end

    ##
    # Where users should return a hash or
    # an array of hashes representing Kubernetes resources
    # @yield [bucket] Description of block
    # @return [Array<Hash>] array of hashes representing Kubernetes resources
    def gen(&block)
      if block_given?
        bucket = Kerbi::ResBucket.new(self)
        block.call(bucket)
        bucket.output.flatten
      end
    end

    ##
    # Coerces filename of unknown format to an absolute path
    # @param [String, fname] fname simplified or absolute path of file
    # @return [String] a variation of the filename that exists
    def resolve_file_name(fname)
      dir = self.class.class_pwd
      Kerbi::Utils.real_files_for(
        fname,
        "#{fname}.yaml",
        "#{fname}.yaml.erb",
        "#{dir}/#{fname}",
        "#{dir}/#{fname}.yaml",
        "#{dir}/#{fname}.yaml.erb"
      ).first
    end

    ##
    # Finds all .yaml and .yaml.erb files in a directory
    # @param [String, dir] dir relative or absolute path of the directory
    # @param [Array<String>], blacklist] blacklist list of filenames to avoid
    # @return [Array<Hash>] array of processed hashes
    def inflate_yamls_in_dir(dir=nil, blacklist=nil)
      dir ||= pwd
      blacklist ||= []

      dir = "#{pwd}/#{dir}" if dir.start_with?(".")
      yaml_files = Dir["#{dir}/*.yaml"]
      erb_files = Dir["#{dir}/*.yaml.erb"]

      (yaml_files + erb_files).map do |fname|
        is_blacklisted = blacklist.include?(File.basename(fname))
        inflate_yaml_file(fname) unless is_blacklisted
      end.compact.flatten
    end

    ##
    # Inflates a yaml/erb file into a Hash
    # @param [String, fname] fname simplified or absolute name of file
    # @param [Hash, extras] extras an additional hash available to ERB
    # @return [[Hash]] array of inflated hashes
    def load_yaml_file(fname, extras = {})
      file = File.read(resolve_file_name(fname))
      binding.local_variable_set(:extras, extras)
      ERB.new(file).result(binding)
    end

    ##
    # Turns hashes into symbol-keyed hashes,
    # and applies white/blacklisting based on filters supplied
    # @param [Array<Hash>] hashes list of inflated hashes
    # @param [Array<Hash>] whitelist list of k8s res IDs to whitelist
    # @param [Array<Hash>] blacklist list of k8s res IDs to blacklist
    # @return [Array<Hash>] list of clean and filtered hashes
    def clean_and_filter_hashes(hashes, whitelist, blacklist)
      hashes = hashes.map(&:deep_symbolize_keys)
      hashes = filter_res_only(hashes, Array(whitelist))
      filter_res_except(hashes, Array(blacklist))
    end

    ##
    # End-to-end loading and processing of a YAML/ERB file
    # @param [String] fname simplified or absolute path of file
    # @param [Hash] extras an additional hash available in the ERB context
    # @param [Array<Hash>] only list of k8s res IDs to whitelist
    # @param [Array<Hash>] except list of k8s res IDs to blacklist
    # @return [Array<Hash>] the hashes loaded from the YAML/ERB
    def inflate_yaml_file(fname, extras: {}, only: nil, except: nil)
      interpolated_yaml = load_yaml_file(fname, extras)
      hashes = YAML.load_stream(interpolated_yaml)
      clean_and_filter_hashes(hashes, only, except)
    end

    ##
    # Convenience instance method for accessing class level pwd
    # @return [String] the subclass' pwd as defined by the user
    def pwd
      self.class.class_pwd
    end

    class << self
      ##
      # Sets the absolute path of the directory where
      # yamls used by this Gen can be found, usually "__dir__"
      # @param [String] dirname absolute path of the directory
      # @return [void]
      def locate_self(dirname)
        @dir_location = dirname
      end

      ##
      # Returns the value set by locate_self
      # @return [String] the subclass' pwd as defined by the user
      def class_pwd
        @dir_location
      end
    end

    private

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

end