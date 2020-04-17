require "base64"
require_relative 'values_manager'

module Kerb
  class App
    attr_accessor :values_helper
    attr_accessor :generators

    def values
      @values ||= ValuesManager.load(values_helper)
    end

    def gen
      self.generators.inject([]) do |whole, gen_class|
        generator = gen_class.new(values)
        whole + generator.gen.flatten
      end
    end

    def gen_yaml
      self.gen.map{|h|YAML.dump(h)}.join("\n")
    end
  end
end

def kerb
  @kerb ||= Kerb::App.new
end