module Kerbi
  module Utils
    class Utils

      class << self
        def real_files_for(*candidates)
          candidates.select do |fname|
            File.exists?(fname)
          end
        end

        def flatten_hash(hash)
          hash.each_with_object({}) do |(k, v), h|
            if v.is_a? Hash
              flatten_hash(v).map do |h_k, h_v|
                h["#{k}.#{h_k}".to_sym] = h_v
              end
            else
              h[k] = v
            end
          end
        end
      end

    end
  end
end