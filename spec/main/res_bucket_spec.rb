require_relative './../spec_helper'


RSpec.describe Kerbi::ResBucket do

  let(:mixer) { Kerbi::Mixer.new({}) }
  subject { Kerbi::ResBucket.new(mixer) }

  let(:root) { '/tmp/kerbi-yamls' }

  def make_yaml(fname, contents)
    File.open("#{root}/#{fname}", "w") do |f|
      contents = YAML.dump(contents) if contents.is_a?(Hash)
      f.write(contents)
    end
  end

  before :each do
    system "rm -rf #{root}"
    system "mkdir #{root}"
    Kerbi::Mixer.locate_self root
  end

  describe '#github' do
    it 'outputs the correct hash list' do
      subject.github(
        id: 'nectar-cs/nectarines',
        file: 'wiz-ci/kerbi/values.yaml'
      )
      expect(subject.output.first&.keys.count).to eq(3)
    end
  end

  describe '#yaml' do
    it 'returns the correct hash list' do
      make_yaml('a.yaml', a_foo: 'bar')
      make_yaml('b.yaml', b_foo: 'baz')
      subject.yaml 'a'
      expect(subject.output).to eq([{a_foo: "bar"}])
    end
  end

  describe 'hash' do
    it 'returns the correct hash list' do
      subject.hash(foo: 'bar')
      expect(subject.output).to eq([{foo: "bar"}])
    end
  end

  describe "#mixer" do
    it "returns the correct hash list" do
      class OtherMixer < Kerbi::Mixer
        def run
          [{ foo: "bar #{self.values[:message]}" }]
        end
      end

      subject.mixer OtherMixer, root: { message: "baz" }
      expect(subject.output).to eq([{foo: 'bar baz'}])
    end
  end

  describe 'chart' do
    let(:repo) { "https://kubernetes.github.io/dashboard" }
    let(:chart) { 'kubernetes-dashboard/kubernetes-dashboard' }
    before(:each) { system("helm repo add kubernetes-dashboard #{repo}") }

    context 'with id only' do
      it 'returns the correct hash list' do
        subject.chart(id: chart)
        expect(subject.output.count).to be > 5
      end
    end

    context 'with all options' do
      it 'invokes the parent method correctly' do
        subject.chart(
          id: chart,
          release: 'rspec',
          cli_args: ""
        )
      end
    end
  end

  describe '#yamls' do
    before :each do
      make_yaml('a.yaml', a_foo: 'bar')
      make_yaml('b.yaml', b_foo: 'baz')
      make_yaml('c.yaml.erb', c_foo: 'zab')
    end

    it 'outputs the correct hashes' do
      subject.yamls in: root, except: 'b.yaml'
      expected = [{a_foo: 'bar'}, {c_foo: 'zab'}]
      expect(subject.output).to match_array(expected)
    end
  end

  describe '#patched_with' do
    let(:patch) { {foo: 'baz', bar: {foo: 'bar'}} }
    let(:res) { { bar: {foo: 'baz', bar: 'foo'} } }
    let(:expected) { {foo: "baz", bar: {foo: "bar", bar: "foo"}} }

    context 'with one hash' do
      it 'outputs the correct hashes' do
        subject.patched_with(hash: patch) do |kp|
          kp.hash res
        end
        expect(subject.output).to eq([expected])
      end
    end

    context 'with many hashes' do
      it 'outputs the correct hashes' do
        subject.patched_with hashes: [{x: 'x'}] do |kp|
          kp.hash x: 'y'
        end
        expect(subject.output).to eq([{x: 'x'}])
      end
    end

    context 'with_relative_path' do
      it 'returns the expected hashes' do
        make_yaml('a.yaml', x: 'x')
        subject.patched_with yamls_in: './../kerbi-yamls' do |kp|
          kp.hash x: 'x1'
          kp.hash x: 'x2', z: 'z'
        end
        expect(subject.output).to match_array([{x: 'x'}, {x: 'x', z: 'z'}])
      end
    end
  end
end