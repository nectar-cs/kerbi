require 'tempfile'
require_relative './../gen'

RSpec.describe Kerb::Gen do

  def tmp_file(content)
    f1 = Tempfile.new
    f1 << content
    f1.rewind
    f1.path
  end

  subject do
    Kerb::Gen.new({})
  end

  describe "#res_id" do
    context 'with bad hashes' do
      it 'returns an empty string' do
        expect(subject.res_id({})).to eq('')
        expect(subject.res_id({'kind': 'Volume'})).to eq('')
        expect(subject.res_id({'kind': "Volume", metadata: {}})).to eq('')
      end
    end

    context 'with a proper Kubernetes res hash' do
      it "returns the resource's signature" do
        expect(subject.res_id({
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
        result = subject.filter_res_only(hashes, [nil])
        expect(result).to eq(hashes)

        result = subject.filter_res_except(hashes, [nil])
        expect(result).to eq(hashes)
      end
    end

    context 'with rules' do
      it 'returns the ruled-in hash' do
        result = subject.filter_res_only(hashes, ['KindA:NameA'])
        expect(result).to eq([hashes[0]])

        result = subject.filter_res_except(hashes, ['KindA:NameA'])
        expect(result).to eq([hashes[1]])
      end
    end
  end

  describe "#resolve_file_name" do
    context 'when fname is not a real file' do
      it 'returns the assumed fully qualified name' do
        allow(subject.class).to receive(:get_location).and_return('/foo')
        expect(subject.resolve_file_name('bar')).to eq('/foo/bar.yaml.erb')
      end
    end

    context 'when fname is a real file' do
      it 'returns the original fname'do
        result = subject.resolve_file_name('/dev/null')
        expect(result).to eq('/dev/null')
      end
    end
  end

  describe 'interpolate' do
    context 'without extras or a binding' do
      it 'returns the interpolated yaml as a hash' do
        f = tmp_file(YAML.dump({ k1: 'v1' }))
        expect(subject.interpolate(f, {})).to eq("---\n:k1: v1\n")
      end
    end

    context 'with extras' do
      it 'reads the extras in the extras hash' do
        f = tmp_file("k1: <%=extras[:v1]%>")
        result = subject.interpolate(f, {v1: 'foo'})
        expect(result).to eq("k1: foo")
      end
    end

    context 'with bindings' do
      subject { Kerb::Gen.new({x: 'y'}) }
      it 'reads the values hash' do
        f = tmp_file("k1: <%= values[:x] %>")
        expect(subject.interpolate(f)).to eq("k1: y")
      end

      it 'reads regular instance methods' do
        class Kerb::Gen; def x() 'yy' end; end
        f = tmp_file("k1: <%= x %>")
        expect(subject.interpolate(f)).to eq("k1: yy")
      end
    end
  end
end