require 'kerbi'

class Main < Kerbi::Gen
  def gen
    safe_gen do |k|
      k.yaml 'ingress'
      k.yamls './common-resources-dir'
      k.patched_with yamls: ['annotations'] do
        k.hash kind: "Deployment", metadata: {} #etc
      end
    end

    def ingress_enabled?
      !!self.values[:ingress]
    end
  end
end

kerbi.generators = [ Main ]

puts kerbi.gen_yaml