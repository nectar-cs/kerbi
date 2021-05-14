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

  describe "$release_name" do
    it "is available after reading the values" do
      ARGV.replace(%w[template foo])
      kerbi.values
      expect($release_name).to eq('foo')
    end
  end

  describe '#cli_exec' do
    context 'with template cmd' do
      it 'prints the template YAML' do
        subject.generators = [MixerA, MixerB]
        ARGV.replace(%w[template foo])
        expect { subject.cli_exec }.to output(YAML_OUT).to_stdout
      end
    end

    context 'with values cmd' do
      it 'prints the values YAML' do
        subject.generators = [MixerA, MixerB]
        ARGV.replace(%w[show values --set x=y])
        expect { subject.cli_exec }.to output("x: y\n").to_stdout
      end
    end

    context 'with preset cmd' do
      it 'prints the values YAML' do
        subject.generators = []
        fname = tmp_file("foo: bart")
        ARGV.replace(['show', 'preset', fname, '--set', 'x=y'])
        expect { subject.cli_exec }.to output("foo: bart\n").to_stdout
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

  describe '#gen' do
    context 'with --only filters' do

      let(:expected) do
        [
          {:kind=>"kind-1", :metadata=>{:name=>"name-1"}},
          {:kind=>"kind-2", :metadata=>{:name=>"name-2"}}
        ]
      end

      it 'selects only the requested resources' do
        subject.generators = [MixerC]
        ARGV.replace(%w[foo --only kind-1:name-1 --only kind-2:name-2])
        expect(subject.gen).to eq(expected)
      end
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

class MixerC < Kerbi::Mixer
  def run
    [
      {
        kind: 'kind-1',
        metadata: { name: 'name-1' }
      },
      {
        kind: 'kind-1',
        metadata: { name: 'name-2' }
      },
      {
        kind: 'kind-2',
        metadata: { name: 'name-2' }
      }
    ]
  end
end

YAML_OUT = "a: a1

---

b: b

---

a: a2
"
