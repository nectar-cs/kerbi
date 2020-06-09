require_relative './../../lib/kerbi'

class HelloWorldMixer < Kerbi::Mixer
  def run
    super do |g|
      message = values[:status] || "almost"
      g.hash({hello: "I am #{message} templating with Kerbi"})
    end
  end
end

kerbi.generators = [ HelloWorldMixer ]

output = kerbi.gen_yaml
puts output
File.open("#{__dir__}/output.yaml", "w") { |f| f.write(output) }