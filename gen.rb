
module Kerb
  class Gen
    attr_reader :values

    def initialize(values)
      @values = values
    end

    def gen
      []
    end

    def res_id(hash)
      "#{hash['kind']}:#{hash['metadata']['name']}" rescue ''
    end

    def filter_res_only(hashes, rules)
      return hashes if rules.compact.empty?
      hashes.select { |hash| rules.include?(res_id(hash)) }
    end

    def filter_res_except(hashes, rules)
      return hashes if rules.compact.empty?
      hashes.reject { |hash| rules.include?(res_id(hash)) }
    end

    def interpolate(fname)
      dir = self.class.get_location
      full_name = "#{dir}/#{fname}.yaml.erb"
      file = File.read(full_name)
      ERB.new(file).result(self.send(:binding))
    end

    def inflate(fname, only: nil, except: nil)
      interpolated_yaml = interpolate(fname)
      hashes = YAML.load_stream(interpolated_yaml)
      hashes = filter_res_only(hashes, Array(only))
      filter_res_except(hashes, Array(except))
    end

    def secrify(string)
      Base64.encode64(string)
    end

    class << self
      def locate_self(val)
        @dir_location = val
      end

      def get_location
        @dir_location
      end
    end
  end
end