require_relative './../spec_helper'

RSpec.describe Kerbi::Engine do

  subject { Kerbi::Engine.new }

  describe "$kerbi" do
    it 'acts as a singleton' do
      expect(kerbi).to eq(kerbi)
      expect(kerbi).to eq($kerbi)
      expect(kerbi).not_to eq(Kerbi::Engine.new)
    end
  end

  describe '#cli_exec' do
    context 'with template cmd' do
      it 'prints the template YAML' do
        subject.generators = [MixerA, MixerB]
        ARGV.replace(['t'])
        expect { subject.cli_exec }.to output(YAML_OUT).to_stdout
      end
    end

    context 'with values cmd' do
      it 'prints the values YAML' do
        subject.generators = [MixerA, MixerB]
        ARGV.replace(%w[v --set x=y])
        expect { subject.cli_exec }.to output("x: y\n").to_stdout
      end
    end
  end

  describe '#gen_yaml' do
    it 'outputs the correct yaml string' do
      subject.generators = [MixerA, MixerB]
      output = subject.gen_yaml
      expect(output).to eq(YAML_OUT)
    end
  end

end

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

YAML_OUT = "a: a1

---

b: b

---

a: a2
"
