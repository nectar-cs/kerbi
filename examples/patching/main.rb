require_relative './../../lib/kerbi'

class PatchingExample < Kerbi::Mixer

  locate_self __dir__

  def run
    super do |g|
      g.hash({should_not_be_patched: "it was not"})
      g.patched_with yamls_in: './patches' do |patched|
        patched.yaml 'resources'
      end
    end
  end
end

kerbi.generators = [PatchingExample]

output = kerbi.gen_yaml
puts output
File.open("#{__dir__}/output.yaml", "w") { |f| f.write(output) }