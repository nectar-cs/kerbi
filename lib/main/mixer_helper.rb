require "base64"

module Kerbi
  module MixerHelper

    ##
    #
    # @param [String] string to be base64 encoded
    def b64_encode_secret(string)
      string ? Base64.encode64(string) : ''
    end

    ##
    # @param [Hash] opts options
    # @option opts [String] url full URL to raw yaml file contents on the web
    # @option opts [String] from one of [github]
    # @option opts [String] except list of filenames to avoid
    # @raise [Exception] if project-id/file missing in github hash
    def http_descriptor_to_url(**opts)
      return opts[:url] if opts[:url]

      if opts[:from] == 'github'
        base = "https://raw.githubusercontent.com"
        branch = opts[:branch] || 'master'
        project, file = (opts[:project] || opts[:id]), opts[:file]
        raise "Project and/or file not found" unless project && file
        "#{base}/#{project}/#{branch}/#{file}"
      end
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
  end
end