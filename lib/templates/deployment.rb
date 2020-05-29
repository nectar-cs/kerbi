require_relative 'res_template'

module Kerbi
  class DeploymentTemplate < Kerbi::ResTemplate

    class << self
      def container(name:, image:, cmd:, envs:, image_pull_policy:)
        cmd = cmd.split(' ') unless cmd.is_a?(Array)
        {
          name: name,
          image: image,
          imagePullPolicy: image_pull_policy,
          command: cmd,
          env: envs
        }
      end

      def generic(subs)
        {
          kind: 'Deployment',
          apiVersion: 'apps/v1',
          metadata: metadata(subs),
          spec: {
            replicas: subs[:replicas] || 1,
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