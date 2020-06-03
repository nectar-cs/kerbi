require_relative 'res_template'

module Kerbi
  class DeploymentTemplate < Kerbi::ResTemplate

    class << self
      def container(**options)
        defaults = { name: 'main', ipp: 'Always', env: [] }
        options = defaults.merge(options)
        command = options[:cmd] || options[:command]
        command = command&.split(' ') unless command.is_a?(Array)

        {
          name: options[:name],
          image: options[:image],
          imagePullPolicy: options[:image_pull_policy] || options[:ipp],
          command: command,
          env: options[:envs] || options[:env]
        }
      end

      def generic(subs)
        {
          kind: 'Deployment',
          apiVersion: 'apps/v1',
          metadata: metadata(subs),
          spec: {
            replicas: (subs[:replicas] || 1).to_i,
            selector: {
              matchLabels: meta_labels(subs[:name], subs[:selector_labels])
            },
            template: {
              metadata: metadata(subs),
              spec: {
                initContainers: subs[:init_containers],
                containers: subs[:containers]
              }
            }
          }
        }
      end
    end
  end
end