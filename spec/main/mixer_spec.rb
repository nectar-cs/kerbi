require_relative './../spec_helper'
require_relative './../../lib/main/gen'

RSpec.describe Kerbi::Mixer do

  let(:root) { '/tmp/kerbi-yamls' }

  def make_yaml(fname, contents)
    File.open("#{root}/#{fname}", "w") do |f|
      f.write(YAML.dump(contents))
    end
  end

  before :each do
    system "rm -rf #{root}"
    system "mkdir #{root}"
  end

  subject { Kerbi::Mixer.new({}) }

  describe "#gen2" do
    it 'works' do
      result = subject.run do |r|
        r.yaml tmp_file(YAML.dump({ k1: 'v1' }))
        r.hash k2: 'v2'
      end
      expect(result).to eq([{k1: 'v1'}, {k2: 'v2'}])
    end
  end

  describe '#patched_with' do
    let(:patch) { {foo: 'baz', bar: {foo: 'bar'}} }
    let(:res) { { bar: {foo: 'baz', bar: 'foo'} } }
    let(:expected) { {foo: "baz", bar: {foo: "bar", bar: "foo"}} }

    context 'with one hash' do
      it 'outputs the correct hashes' do
        actual = subject.run do |k|
          k.patched_with(hash: patch) { |kp| kp.hash res }
        end
        expect(actual).to eq([expected])
      end
    end

    context 'with many hashes' do
      it 'outputs the correct hashes' do
        actual = subject.run do |k|
          k.patched_with hashes: [{x: 'x'}] do |kp|
            kp.hash x: 'y'
          end
        end
        expect(actual).to eq([{x: 'x'}])
      end
    end

    context 'with_relative_path' do
      it 'returns the expected hashes' do
        allow(subject.class).to receive(:class_pwd).and_return(root)
        make_yaml('a.yaml', x: 'x')

        actual = subject.run do |k|
          k.patched_with yamls_in: './../kerbi-yamls' do |kp|
            kp.hash x: 'x1'
            kp.hash x: 'x2', z: 'z'
          end
        end
        expect(actual).to match_array([{x: 'x'}, {x: 'x', z: 'z'}])
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
      actual = subject.run do |k|
        k.yamls in: root, except: 'b.yaml'
      end
      expected = [{a_foo: 'bar'}, {c_foo: 'zab'}]
      expect(actual).to match_array(expected)
    end
  end

  describe ".locate_self" do
    it "stores and later outputs the value" do
      class Subclass < Kerbi::Mixer
        locate_self 'foo'
      end
      expect(Subclass.new({}).class.class_pwd).to eq('foo')
    end
  end

  describe "#res_id" do
    context 'with bad hashes' do
      it 'returns an empty string' do
        expect(subject.simple_k8s_res_id({})).to eq('')
        expect(subject.simple_k8s_res_id({'kind': 'Volume'})).to eq('')
        expect(subject.simple_k8s_res_id({'kind': "Volume", metadata: {}})).to eq('')
      end
    end

    context 'with a proper Kubernetes res hash' do
      it "returns the resource's signature" do
        expect(subject.simple_k8s_res_id({
          kind: "Volume",
          metadata: { name: "foo" }
        })).to eq('Volume:foo')
      end
    end
  end

  describe '#filter_res_only / #filter_res_except' do
    let :hashes do [
      {kind: 'KindA', metadata: {name: 'NameA'}},
      {kind: 'KindB', metadata: {name: 'NameB'}}
    ] end

    context 'without rules' do
      it 'returns the original input' do
        #noinspection InvalidCallToProtectedPrivateMethod
        result = subject.filter_res_only(hashes, [nil])
        expect(result).to eq(hashes)

        #noinspection InvalidCallToProtectedPrivateMethod
        result = subject.filter_res_except(hashes, [nil])
        expect(result).to eq(hashes)
      end
    end

    context 'with rules' do
      it 'returns the ruled-in hash' do
        #noinspection InvalidCallToProtectedPrivateMethod
        result = subject.filter_res_only(hashes, ['KindA:NameA'])
        expect(result).to eq([hashes[0]])

        #noinspection InvalidCallToProtectedPrivateMethod
        result = subject.filter_res_except(hashes, ['KindA:NameA'])
        expect(result).to eq([hashes[1]])
      end
    end
  end

  describe "#resolve_file_name" do
    before :each do
      allow(subject.class).to receive(:class_pwd).and_return(root)
    end

    context 'when fname is not a real file' do
      it 'returns the assumed fully qualified name' do
        expect(subject.resolve_file_name('bar')).to eq(nil)
      end
    end

    context 'when fname is a real file' do
      it 'returns the original fname'do
        make_yaml('foo.yaml', {})
        expected = "#{root}/foo.yaml"
        expect(subject.resolve_file_name('foo')).to eq(expected)
        expect(subject.resolve_file_name('foo.yaml')).to eq(expected)
      end
    end
  end

  describe 'interpolate' do
    context 'without extras or a binding' do
      it 'returns the interpolated yaml as a hash' do
        f = tmp_file(YAML.dump({ k1: 'v1' }))
        expect(subject.load_yaml_file(f, {})).to eq("---\n:k1: v1\n")
      end
    end

    context 'with extras' do
      it 'reads the extras in the extras hash' do
        f = tmp_file("k1: <%=extras[:v1]%>")
        result = subject.load_yaml_file(f, {v1: 'foo'})
        expect(result).to eq("k1: foo")
      end
    end

    context 'with bindings' do
      subject { Kerbi::Mixer.new({x: 'y'}) }
      it 'reads the values hash' do
        f = tmp_file("k1: <%= values[:x] %>")
        expect(subject.load_yaml_file(f)).to eq("k1: y")
      end

      it 'reads regular instance methods' do
        class Kerbi::Mixer; def xx() 'yy' end; end
        f = tmp_file("k1: <%= xx %>")
        expect(subject.load_yaml_file(f)).to eq("k1: yy")
      end
    end
  end

  describe '#gen' do
    it 'raises unimplemented' do
      expect{subject.run}.to raise_exception("Unimplemented")
    end
  end

  describe "#inflate_yaml" do
    class Kerbi::Mixer;
      def kind_a() 'KindA' end
      def kind_b() 'KindB' end
    end

    let :full_hashes do [
      { kind: "KindA", metadata: {name: "A"} },
      { kind: "KindB", metadata: {name: "B"} },
      { x: 'y' }
    ] end

    let :hashes do [
      { kind: "<%= kind_a %>", metadata: {name: "A"} },
      { kind: "<%= kind_b %>", metadata: {name: "B"} },
      { x: 'y' }
    ] end
    let :f do
      tmp_file(YAML.dump_stream(*hashes))
    end

    context 'without filters' do
      it 'performs correctly' do
        result = subject.inflate_yaml_file(f)
        expect(result).to eq(full_hashes)
      end
    end

    context 'with only filter' do
      it 'performs correctly' do
        result = subject.inflate_yaml_file(f, only: "KindA:A")
        expect(result).to eq([full_hashes[0]])
      end
    end

    context 'with only filter' do
      it 'performs correctly' do
        result = subject.inflate_yaml_file(f, except: "KindB:B")
        expect(result).to eq([full_hashes[0], full_hashes[2]])
      end
    end
  end
end