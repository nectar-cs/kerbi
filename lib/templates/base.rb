module Kerbi
  module Template
    class Base
      class << self
        def meta_labels(name, labels)
          labels.nil? ? { app: name } : labels
        end

        def metadata(subs)
          {
            name: subs[:name],
            namespace: subs[:ns],
            labels: meta_labels(subs[:name], subs[:labels])
          }
        end
      end
    end
  end
end