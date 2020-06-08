require_relative './../../lib/kerbi'

class SelectingExample < Kerbi::Mixer

  locate_self __dir__

  def run
    super do |g|
      g.yaml 'resources', only: ['ConfigMap:wanted']
      g.yamls in: './other-yamls', except: 'unwanted.yaml'
    end
  end
end

kerbi.generators = [SelectingExample]

output = kerbi.gen_yaml
puts output
File.open("#{__dir__}/output.yaml", "w") { |f| f.write(output) }