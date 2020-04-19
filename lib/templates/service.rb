require_relative 'res_template'

module Kerbi
  class ServiceTemplate < Kerbi::ResTemplate
    class << self

      def port(port_obj)
        port_obj = { port: port_obj } unless port_obj.is_a?(Hash)
        {
          port: port_obj[:port],
          targetPort: port_obj[:target_port] || port_obj[:port],
          protocol: port_obj[:protocol] || 'TCP'
        }
      end

      def generic_service(subs)
        {
          kind: 'Service',
          metadata: metadata(subs),
          spec: {
            type: subs[:type] || 'ClusterIP',
            selector: meta_labels(subs[:name], subs[:selector_labels]),
            ports: subs[:ports].map{|p|port(p)}
          }
        }
      end
    end
  end
end