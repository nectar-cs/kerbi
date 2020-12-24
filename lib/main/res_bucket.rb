module Kerbi
  class ResBucket

    ##
    # Array of res-hashes being aggregated
    # @return [Array<Hash>] list of hashes
    attr_accessor :output

    ##
    # Reference to the generator that owns this bucket
    # @return [Kerbi::Mixer] reference to the generator that owns this bucket
    attr_accessor :parent

    ##
    # Constructor
    # @param [Kerbi::Mixer] parent the Kerbi::Mixer that owns this bucket
    def initialize(parent)
      @parent = parent
      @output = []
    end

    ##
    # Adds the res-hashes from a YAML/ERB file
    # @param [String] fname simplified or absolute path of file
    # @param [Hash] extras an additional hash available in the ERB context
    # @param [Array<String>] only list of k8s res IDs to whitelist
    # @param [Array<String>] except list of k8s res IDs to blacklist
    # @return [void]
    #
    def yaml(fname, extras: {}, only: nil, except: nil)
      self.output += parent.inflate_yaml_file(fname, only, except, extras)
    end

    ##
    # Adds all res-hashes from loaded from .yaml and .yaml.erb files in a directory
    # @param [Hash] opts keyword arguments
    # @option opts [String] in absolute or relative path to the directory
    # @option opts [Array<String>] except list of filenames to avoid
    # @return [void]
    def yamls(**opts)
      dir, blacklist = opts.slice(:in, :except).values
      self.output += self.parent.inflate_yamls_in_dir(dir, [blacklist].compact, nil)
    end

    ##
    # Patches all res-hashes loaded in block with the given hashes.
    # Patches are sequentially deep-merged onto the res-hashes
    #
    # @param [Hash] opts keyword arguments
    # @option opts [Hash] hash single hash to apply as patch
    # @option opts [Array<Hash>] many hashes to apply as patches
    # @option opts [Array<String>] yamls list of simplified/absolute filenames to apply as patches
    # @option opts [String] yamls_in dir name in which all yamls/erbs should be applied as hashes
    # @yield [bucket] Exec context in which hashes are collected into one bucket
    # @yieldparam [Kerbi::ResBucket] gp Bucket object with essential methods
    # @yieldreturn [Array<Hash>] array of hashes representing Kubernetes resources
    # @return [void]
    def patched_with(**opts, &block)
      bucket = self.class.new(self.parent)
      block.call(bucket)

      hashes = opts[:hashes] || [opts[:hash]]
      yamls_in = opts.has_key?(:yamls_in) && opts[:yamls_in]
      #noinspection RubyYardParamTypeMatch
      dir_patches = yamls_in && self.parent.inflate_yamls_in_dir(yamls_in, [], {})
      file_patches = (opts[:yamls] || []).map do |f|
        parent.inflate_yaml_file(f, nil, nil, {})
      end
      patches = (hashes + file_patches + (dir_patches || [])).flatten.compact

      self.output += bucket.output.flatten.map do |res|
        patches.inject(res) do |whole, patch|
          whole.deep_merge(patch)
        end
      end
    end

    def mixer(sibling_class, root: self.parent.values)
      self.output += sibling_class.new(root).run
    end

    ##
    # Adds a raw hash to the bucket
    # @param [Hash] hash the hash to be added
    def hash(hash)
      self.output += parent.clean_and_filter_hashes([hash], nil, nil)
    end

    ##
    # Adds a raw hash to the bucket
    # @param [Array<Hash>] hashes the hashes the hash to be added
    # @param [Array<String>] only optional whitelist of k8s-ids
    # @param [Array<String>] except optional blacklist of k8s-ids
    def hashes(hashes, only: nil, except: nil)
      self.output += parent.clean_and_filter_hashes(hashes, only, except)
    end

    ##
    # Adds the res-hashes from a YAML/ERB file in a github repo
    # @param [String] id <org>/<repo>
    # @param [String] file /path/to/file.extension
    # @param [Array<String>] only optional whitelist of k8s-ids
    # @param [Array<String>] except optional blacklist of k8s-ids
    def github(id:, file:, only: nil, except: nil)
      params = {from: 'github', id: id, file: file}
      self.output += parent.inflate_yaml_http(params, only, except, {})
    end

    def tam_api(url, deep_root_key)

    end

    ##
    # Runs the helm template command
    # @param [Hash] opts kwargs
    # @option opts [String] release release name to pass to Helm
    # @option opts [String] project <org>/<chart> string identifying helm chart
    # @option opts [Hash] values hash of values to patch chart values
    # @option opts [Hash] inline_assigns inline values for --set
    # @option opts [String] cli_args extra cli args for helm
    # @option opts [Array<String>] only list res-id's to whitelist from results
    # @option opts [Array<String>] except list res-id's to blacklist from results
    # @return [Array<Hash>] list of res-hashes
    def chart(**opts)
      whitelist, blacklist = [opts.delete(:only), opts.delete(:except)]
      self.output += self.parent.inflate_helm_output(
        opts, whitelist, blacklist
      )
    end

    private

    def method_missing(method, *args)
      parent.send(method, *args) if parent.respond_to?(method)
      super
    end
  end
end