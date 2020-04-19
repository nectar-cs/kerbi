require_relative 'res_template'

module Kerbi
  class EnvVarTemplate < Kerbi::ResTemplate
    class << self
      def generic(hash)
        raise "One tuple per hash" unless hash.keys.one?
        key, value = hash.first
        if value.is_a? Hash
          type, bundle = value.first
          object_name, in_object_key = bundle.first
          if type == :secret
            secret_var(key.to_s, object_name.to_s, in_object_key)
          elsif type == :config
            config_var(key.to_s, object_name.to_s, in_object_key)
          else
            raise "Can't handle #{type}"
          end
        else
          flat_var(key.to_s, value)
        end
      end

      def generics(hashes)
        hashes.map do |key, value|
          generic key => value
        end
      end

      def flat_var(name, value)
        { name: name.upcase, value: value }
      end

      def secret_var(name, sec_name, sec_key)
        {
          name: name.upcase,
          valueFrom: {
            secretKeyRef: {
              name: sec_name,
              key: sec_key
            }
          }
        }
      end

      def config_var(name, sec_name, sec_key)
        {
          name: name.upcase,
          valueFrom: {
            configMapRef: {
              name: sec_name,
              key: sec_key
            }
          }
        }
      end
    end
  end
end