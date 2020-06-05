require 'yaml'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'
require_relative './base_helper'
require_relative './../utils/utils'
require_relative './res_bucket'

module Kerbi
  class Mixer
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
    # @yield [bucket] Exec context in which hashes are collected into one bucket
    # @yieldparam [Kerbi::ResBucket] g Bucket object with essential methods
    # @yieldreturn [Array<Hash>] array of hashes representing Kubernetes resources
    # @return [Array<Hash>] array of hashes representing Kubernetes resources
    def evaluate(&block)
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
    # @param [Hash] opts options
    # @option opts [String] url full URL to raw yaml file contents on the web
    # @option opts [String] from one of [github]
    # @option opts [String] except list of filenames to avoid
    # @raise [Exception] if project-id/file missing in github hash
    def http_descriptor_to_url(opts={})
      return opts[:url] if opts[:url]

      if opts[:from] == 'github'
        base = "https://raw.githubusercontent.com"
        branch = opts[:branch] || 'master'
        file, project = opts[:id], opts[:file]
        raise "Project and/or file not found" unless project && file
        "#{base}/#{project}/#{branch}/#{file}"
      end
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
    # 
    # @param [Hash] opts http options passed to http_descriptor_to_url
    # @param [Array<String>] whitelist list res-id's to whitelist from results
    # @param [Array<String>] blacklist list res-id's to blacklist from results
    # @param [Hash] extras additional hash passed to ERB
    # @return [Array<Hash>] list of res-hashes
    def inflate_yaml_http(opts, whitelist, blacklist, extras)
      yaml_url = self.http_descriptor_to_url(opts)
      content = HTTP.get(yaml_url).to_s rescue ''
      self.inflate_raw_str(content, whitelist, blacklist, extras)
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
    # Convenience instance method for accessing class level pwd
    # @return [String] the subclass' pwd as defined by the user
    def pwd
      self.class.class_pwd
    end

    ##
    # Stringifies a k8s resource's identity with a simple scheme
    # @param [Hash] k8s_res_hash hash representing k8s res
    # @return [String] simple string rep e.g Pod:my-pod
    def simple_k8s_res_id(k8s_res_hash)
      kind = k8s_res_hash[:kind]
      name = k8s_res_hash[:metadata]&.[](:name)
      kind && name ? "#{kind}:#{name}" : ''
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
      return hashes if rules.compact.empty?
      hashes.select { |hash| rules.include?(simple_k8s_res_id(hash)) }
    end

    ##
    # Filters by blacklist if rules are given using simple k8s res-ids
    # @param [Array<Hash>] hashes k8s res-hashes
    # @param [Array<String>] rules list of simple k8s res-ids by which to filter
    # @return [Array<Hash>] list of clean and filtered hashes
    def filter_res_except(hashes, rules)
      return hashes if rules.compact.empty?
      hashes.reject { |hash| rules.include?(simple_k8s_res_id(hash)) }
    end
  end
end