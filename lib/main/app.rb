require "base64"
require_relative 'val_man'

module Kerbi
  class App
    ##
    # Optional reference to a helper
    attr_accessor :values_helper

    ##
    # Shat
    attr_accessor :generators

    def values
      @_values ||= ValuesLoader.load
    end

    ##
    # It goes here
    #
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