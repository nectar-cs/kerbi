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
    # @param [Array<Hash>] only list of k8s res IDs to whitelist
    # @param [Array<Hash>] except list of k8s res IDs to blacklist
    # @return [void]
    #
    def yaml(fname, extras: {}, only: nil, except: nil)
      args = [fname, extras, only, except]
      self.output << parent.inflate_yaml_file(*args)
    end

    ##
    # Adds all res-hashes from loaded from .yaml and .yaml.erb files in a directory
    # @param [Hash] opts keyword arguments
    # @option opts [String] in absolute or relative path to the directory
    # @option opts [Array<String>] except list of filenames to avoid
    # @return [void]
    def yamls(opts={})
      dir, blacklist = opts.slice(:in, :except).values
      self.output += self.parent.inflate_yamls_in_dir(dir, [blacklist].compact)
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
    # @return [void]
    def patched_with(opts={}, &block)
      bucket = self.class.new(self.parent)
      block.call(bucket)

      hashes = opts[:hashes] || [opts[:hash]]
      yamls_in = opts.has_key?(:yamls_in) && opts[:yamls_in]
      #noinspection RubyYardParamTypeMatch
      dir_patches = yamls_in && self.parent.inflate_yamls_in_dir(yamls_in)
      file_patches = (opts[:yamls] || []).map do |f|
        parent.inflate_yaml_file(f, nil, nil, {})
      end
      patches = (hashes + file_patches + (dir_patches || [])).flatten.compact

      self.output = bucket.output.flatten.map do |res|
        patches.inject(res) do |whole, patch|
          whole.deep_merge(patch)
        end
      end
    end

    def sibling(sibling_class, root=self.parent.values)
      self.output += sibling_class.new(root).run
    end

    ##
    # Adds a raw hash to the bucket
    # @param [Array<Hash>] hash the hash or hashes the hash to be added
    # @param [Array<String>] only optional whitelist of k8s-ids
    # @param [Array<String>] except optional blacklist of k8s-ids
    def hash(hash, only: nil, except: nil)
      hash = [hash] unless hash.is_a?(Array)
      self.output << parent.clean_and_filter_hashes(hash, only, except)
    end

    ##
    # Adds the res-hashes from a YAML/ERB file in a github repo
    # @param [String] id <org>/<repo>
    # @param [String] file /path/to/file.extension
    # @param [Array<String>] only optional whitelist of k8s-ids
    # @param [Array<String>] except optional blacklist of k8s-ids
    def github(id:, file:, only: nil, except: nil)
      params = {from: 'github', id: id, file: file}
      self.output << parent.inflate_yaml_http(params, only, except, {})
    end

    private

    def method_missing(method, *args)
      parent.send(method, *args) if parent.respond_to?(method)
      super
    end
  end
end