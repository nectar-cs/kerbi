require "base64"
require_relative 'values_manager'

module Kerbi
  ##
  # Singleton class providing the user an interface with Kerbi
  class Engine
    ##
    # List of generators to produce hash-resources for YAMLification
    # @return [Array<Kerbi::Mixer>] array of generators
    attr_accessor :generators

    ##
    # Memoized values loaded by ValuesLoader
    # @return [SymbolHash] values tree to be passed to generators
    def values
      @_values ||= ValuesManager.load
    end

    ##
    # Serializes all generators' outputs into a YAML string
    # @return [String] YAML string of all generator-produced resources
    def gen_yaml
      self.gen.each_with_index.map do |h, i|
        raw = YAML.dump(h.deep_stringify_keys)
        raw.gsub("---\n", i.zero? ? '' : "---\n\n")
      end.join("\n")
    end

    def values_yaml
      YAML.dump(self.values.deep_stringify_keys)
    end

    ##
    # Tami-adherent CLI arg routing
    # @return [void] Prints any output to stdout
    def cli_exec
      command = ARGV.first
      if %w[t template].include?(command)
        puts self.gen_yaml
      elsif %w[v values].include?(command)
        puts self.values_yaml
      else
        puts "Unrecognized command #{command}"
        exit 1
      end
    end

    protected

    def gen
      self.generators.inject([]) do |whole, gen_class|
        generator = gen_class.new(values)
        whole + generator.run.flatten
      end
    end
  end
end

##
# The singleton Kerbi::Engine, where the user can add generators invoke invoke the templating engine
# @return [Kerbi::Engine] singleton instance of Kerbi::App
def kerbi
  $kerbi ||= Kerbi::Engine.new
end