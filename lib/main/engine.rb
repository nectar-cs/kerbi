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

    def arg_values(name)
      indicies = ARGV.each_index.select { |i| ARGV[i]==name }
      indicies.map { |key_index| ARGV[key_index + 1] }
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
      raw = YAML.dump(self.values.deep_stringify_keys)
      raw.gsub("---\n", '')
    end

    ##
    # Tami-adherent CLI arg routing
    # @return [void] Prints any output to stdout
    def cli_exec
      if ARGV.first == 'template'
        puts self.gen_yaml
      elsif ARGV[0..1] == %w[show values]
        puts self.values_yaml
      else
        puts "Unrecognized command #{ARGV}"
        exit 1
      end
    end

    def gen
      res_defs = self.generators.inject([]) do |whole, gen_class|
        generator = gen_class.new(values)
        whole + generator.run.flatten
      end

      if (filters = arg_values('--only')).any?
        res_defs = res_defs.select do |res_def|
          res_def = res_def.deep_symbolize_keys
          kind = res_def[:kind]
          name = res_def.dig(:metadata, :name)
          positive_filters = filters.select do |filter|
            against_kind, against_name = filter.split(":")
            against_kind == kind && against_name == name
          end
          positive_filters.any?
        end
      end
      res_defs
    end
  end
end

##
# The singleton Kerbi::Engine, where the user can add
# generators invoke invoke the templating engine
# @return [Kerbi::Engine] singleton instance of Kerbi::App
def kerbi
  $kerbi ||= Kerbi::Engine.new
end

def tami_sleep
  while true
    sleep 10
  end
end
