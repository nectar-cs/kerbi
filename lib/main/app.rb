require "base64"
require_relative 'val_man'

module Kerbi
  class App
    attr_accessor :values_helper
    attr_accessor :generators

    def values
      ValMan.load(values_helper)
    end

    def gen
      self.generators.inject([]) do |whole, gen_class|
        generator = gen_class.new(values)
        whole + generator.gen.flatten
      end
    end

    def gen_yaml
      self.gen.each_with_index.map do |h, i|
        raw = YAML.dump(h.deep_stringify_keys)
        raw.gsub("---\n", i.zero? ? '' : "---\n\n")
      end.join("\n")
    end
  end
end

def kerbi
  @kerbi ||= Kerbi::App.new
end