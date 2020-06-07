module Kerbi
  module Utils
    class Config
      attr_accessor :bundle

      def initialize
        self.bundle = {
          tmp_helm_values_path: '/tmp/kerbi-helm-vals.yaml',
          helm_exec: "helm"
        }
      end

      def tmp_helm_values_path
        self.bundle[:tmp_helm_values_path]
      end

      def helm_exec
        self.bundle[:helm_exec]
      end

      def tmp_helm_values_path=(val)
        self.bundle[:tmp_helm_values_path] = val
      end

      def helm_exec=(val)
        self.bundle[:helm_exec] = val
      end
    end
  end
end

def config
  $_config ||= Kerbi::Utils::Config.new
end