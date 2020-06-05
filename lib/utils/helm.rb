module Kerbi
  module Utils
    class Helm
      class << self

        ##
        # Tests whether Kerbi can invoke Helm commands
        # @return [Boolean] true if helm commands succeed locally
        def can_exec?
          !!system('helm')
        end

        def create_local_dir

        end

        def template

        end
      end
    end
  end
end