require_relative 'base'

module Kerbi
  module Template
    class Deployment < Kerbi::Template::Base

      class << self
        def container(name:, image:, cmd:, envs:, image_pull_policy:)
          cmd = cmd.split(' ') unless cmd.is_a?(Array)
          {
            name: name || 'main',
            image: image,
            imagePullPolicy: image_pull_policy || 'IfNotPresent',
            command: cmd || '',
            env: envs || []
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
                  containers: subs[:containers],
                  imagePullSecrets: subs[:image_pull_secrets] || []
                }
              }
            }
          }
        end
      end
    end
  end
end