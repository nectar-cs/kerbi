module Kerbi
  class Utils
    class << self
      def real_files_for(*candidates)
        candidates.select do |fname|
          File.exists?(fname)
        end
      end
    end
  end
end