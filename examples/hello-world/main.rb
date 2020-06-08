require_relative './../../lib/kerbi'

class HelloWorldMixer < Kerbi::Mixer
  def run
    super do |g|
      g.hash hello: "I am #{values[:status] || "almost"} templating with Kerbi"
    end
  end
end

kerbi.generators = [ HelloWorldMixer ]
puts kerbi.gen_yaml