require_relative 'base'

module Kerbi
  module Template
    class EnvVar < Kerbi::Template::Base
      class << self
        def generic(hash)
          raise "One tuple per hash" unless hash.keys.one?
          key, value = hash.first
          if value.is_a? Hash
            type, bundle = value.first
            object_name, in_object_key = bundle.first
            if type == :secret
              secret_var(key.to_s, object_name.to_s, in_object_key)
            elsif type == :optional_secret
              secret_var(key.to_s, object_name.to_s, in_object_key, true)
            elsif type == :config
              config_var(key.to_s, object_name.to_s, in_object_key)
            elsif type == :optional_config
              config_var(key.to_s, object_name.to_s, in_object_key, true)
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

        def secret_var(name, sec_name, sec_key, optional=false)
          {
            name: name.upcase,
            valueFrom: {
              secretKeyRef: {
                name: sec_name,
                key: sec_key,
                optional: optional
              }
            }
          }
        end

        def config_var(name, sec_name, sec_key, optional=false)
          {
            name: name.upcase,
            valueFrom: {
              configMapRef: {
                name: sec_name,
                key: sec_key,
                optional: optional
              }
            }
          }
        end
      end
    end
  end
end