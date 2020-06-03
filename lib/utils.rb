module Kerbi
  class Utils
    class << self
      def try_paths(*paths)
        begin
          path = paths.first
          file_cont = File.read(path) rescue nil
          paths = paths[1..-1]
        end until file_cont || paths.nil?
        path if file_cont
      end
    end
  end
end