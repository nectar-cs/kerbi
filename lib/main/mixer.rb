require 'yaml'
require "http"
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'
require_relative './mixer_helper'
require_relative './../utils/utils'
require_relative './res_bucket'

module Kerbi
  class Mixer
    include Kerbi::MixerHelper

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
    # @yield [bucket] Exec context in which hashes are collected into one bucket
    # @yieldparam [Kerbi::ResBucket] g Bucket object with essential methods
    # @yieldreturn [Array<Hash>] array of hashes representing Kubernetes resources
    # @return [Array<Hash>] array of hashes representing Kubernetes resources
    def run(&block)
      if block_given?
        bucket = Kerbi::ResBucket.new(self)
        block.call(bucket)
        bucket.output.flatten
      end
    end

    ##
    # Coerces filename of unknown format to an absolute path
    # @param [String] fname simplified or absolute path of file
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
    # Inflates a yaml/erb file into a Hash
    # @param [String] yaml_str contents of a yaml or yaml.erb
    # @param [Hash] extras an additional hash available to ERB
    # @return [String] original yaml_str interpolated with instance binding
    def interpolate_erb_string(yaml_str, extras)
      binding.local_variable_set(:extras, extras)
      ERB.new(yaml_str).result(binding)
    end

    ##
    # Turns hashes into symbol-keyed hashes,
    # and applies white/blacklisting based on filters supplied
    # @param [Array<Hash>] hashes list of inflated hashes
    # @param [Array<String>] whitelist list/single k8s res ID to whitelist
    # @param [Array<String>] blacklist list/single  k8s res ID to blacklist
    # @return [Array<Hash>] list of clean and filtered hashes
    def clean_and_filter_hashes(hashes, whitelist, blacklist)
      hashes = hashes.map(&:deep_symbolize_keys)
      hashes = filter_res_only(hashes, whitelist)
      filter_res_except(hashes, blacklist)
    end

    ##
    # @param [String] raw_str plain yaml or erb string
    # @param [Array<String>] whitelist list res-id's to whitelist from results
    # @param [Array<String>] blacklist list res-id's to blacklist from results
    # @param [Hash] extras additional hash passed to ERB 
    # @return [Array<Hash>] list of res-hashes
    def inflate_raw_str(raw_str, whitelist, blacklist, extras)
      interpolated_yaml = self.interpolate_erb_string(raw_str, extras)
      hashes = YAML.load_stream(interpolated_yaml)
      clean_and_filter_hashes(hashes, whitelist, blacklist)
    end

    ##
    # End-to-end loading and processing of a YAML/ERB file
    # @param [String] fname simplified or absolute path of file
    # @param [Array<String>] whitelist list res-id's to whitelist from results
    # @param [Array<String>] blacklist list res-id's to blacklist from results
    # @param [Hash] extras additional hash passed to ERB
    # @return [Array<Hash>] list of res-hashes
    def inflate_yaml_file(fname, whitelist, blacklist, extras)
      contents = File.read(resolve_file_name(fname))
      self.inflate_raw_str(contents, whitelist, blacklist, extras)
    end

    ##
    # 
    # @param [Hash] opts http options passed to http_descriptor_to_url
    # @param [Array<String>] whitelist list res-id's to whitelist from results
    # @param [Array<String>] blacklist list res-id's to blacklist from results
    # @param [Hash] extras additional hash passed to ERB
    # @return [Array<Hash>] list of res-hashes
    def inflate_yaml_http(opts, whitelist, blacklist, extras)
      yaml_url = self.http_descriptor_to_url(opts)
      content = HTTP.get(yaml_url).to_s
      self.inflate_raw_str(content, whitelist, blacklist, extras)
    end

    ##
    # Runs the helm template command
    # @param [Hash] opts kwargs
    # @param [Array<String>] whitelist list res-id's to whitelist from results
    # @param [Array<String>] blacklist list res-id's to blacklist from results
    # @option [String] release release name to pass to Helm
    # @option [String] project <org>/<chart> string identifying helm chart
    # @option [Hash] values hash of values to patch chart values
    # @option [Hash] inline_assigns inline values for --set
    # @option [String] cli_args extra cli args for helm
    # @return [Array<Hash>] list of res-hashes
    def inflate_helm_output(opts, whitelist, blacklist)
      raw_yaml = Kerbi::Utils::Helm.template(
        opts[:release] || 'kerbi',
        opts[:id],
        opts[:values] || {},
        opts[:inline_assigns] || {},
        opts[:cli_args]
      )
      self.inflate_raw_str(raw_yaml, whitelist, blacklist, {})
    end

    ##
    # Finds all .yaml and .yaml.erb files in a directory
    # @param [String, dir] dir relative or absolute path of the directory
    # @param [Array<String>] file_blacklist list of filenames to avoid
    # @return [Array<Hash>] array of processed hashes
    def inflate_yamls_in_dir(dir=nil, file_blacklist=nil)
      dir ||= pwd
      blacklist = file_blacklist || []

      dir = "#{pwd}/#{dir}" if dir.start_with?(".")
      yaml_files = Dir["#{dir}/*.yaml"]
      erb_files = Dir["#{dir}/*.yaml.erb"]

      (yaml_files + erb_files).map do |fname|
        is_blacklisted = blacklist.include?(File.basename(fname))
        unless is_blacklisted
          self.inflate_yaml_file(fname, nil, nil, {})
        end

      end.compact.flatten
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

    ##
    # Filters by whitelist if rules are given using simple k8s res-ids
    # @param [Array<Hash>] hashes k8s res-hashes
    # @param [Array<String>] rules list of simple k8s res-ids by which to filter
    # @return [Array<Hash>] list of clean and filtered hashes
    def filter_res_only(hashes, rules)
      return hashes if (rules || []).compact.empty?
      hashes.select { |hash| rules.include?(simple_k8s_res_id(hash)) }
    end

    ##
    # Filters by blacklist if rules are given using simple k8s res-ids
    # @param [Array<Hash>] hashes k8s res-hashes
    # @param [Array<String>] rules list of simple k8s res-ids by which to filter
    # @return [Array<Hash>] list of clean and filtered hashes
    def filter_res_except(hashes, rules)
      return hashes if (rules || []).compact.empty?
      hashes.reject { |hash| rules.include?(simple_k8s_res_id(hash)) }
    end
  end
end