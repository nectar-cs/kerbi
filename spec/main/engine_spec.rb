require_relative './../spec_helper'

RSpec.describe Kerbi::Engine do

  describe "$kerbi" do
    it 'acts as a singleton' do
      expect(kerbi).to eq(kerbi)
      expect(kerbi).to eq($kerbi)
      expect(kerbi).not_to eq(Kerbi::Engine.new)
    end
  end

  describe '#gen_yaml' do
    it 'outputs the correct yaml string' do
      class MixerA < Kerbi::Mixer
        def run
          [{a: 'a1'}]
        end
      end

      class MixerB < Kerbi::Mixer
        def run
          [{b: 'b'}, {a: 'a2'}]
        end
      end

      kerbi.generators = [MixerA, MixerB]
      output = kerbi.gen_yaml
      expected = "a: a1

---

b: b

---

a: a2
"
      expect(output).to eq(expected)
    end
  end

end