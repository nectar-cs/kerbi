require_relative 'res_template'

module Kerbi
  class ServiceTemplate < Kerbi::ResTemplate
    class << self
      def generic(options = {})
        {
          kind: 'Service',
          apiVersion: 'v1',
          metadata: metadata(options),
          spec: {
            type: options[:type] || 'ClusterIP',
            selector: meta_labels(options[:name], options[:selector_labels]),
            ports: (options[:ports] || []).map{|p|port(p)}
          }
        }
      end

      def port(port_obj)
        port_obj = { port: port_obj } unless port_obj.is_a?(Hash)
        {
          port: port_obj[:port],
          targetPort: port_obj[:target_port] || port_obj[:port],
          protocol: port_obj[:protocol] || 'TCP'
        }
      end
    end
  end
end