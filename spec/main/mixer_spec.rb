require_relative './../spec_helper'

RSpec.describe Kerbi::Mixer do

  subject { Kerbi::Mixer.new({}) }

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

  describe "#resolve_file_name" do
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

  describe 'interpolate_erb_string' do
    context 'without ERB' do
      it 'returns the yaml unchanged' do
        actual = subject.interpolate_erb_string("k1: v1", {})
        expect(actual).to eq("k1: v1")
      end
    end

    context 'with ERB' do
      it 'returns the yaml interpolated correctly' do
        expect(subject).to receive(:values).and_return({k: 'foo'})
        yaml = "k1: <%=values[:k]%>\nk2: <%=extras[:k]%>"
        actual = subject.interpolate_erb_string(yaml, {k: 'bar'})
        expect(actual).to eq("k1: foo\nk2: bar")
      end
    end
  end

  describe "#inflate_raw_str" do
    describe 'logic unrelated to filtering' do
      it 'returns the correct list of hashes' do
        yaml = "k1: <%=values[:k1]%>\n---\nk1: bar"
        mixer = Kerbi::Mixer.new({k1: 'foo'})
        actual = mixer.inflate_raw_str(yaml, nil, nil, {})
        expect(actual).to match_array([{k1: 'foo'}, {k1: 'bar'}])
      end
    end
  end

  describe '#inflate_yaml_file' do
    before :each do
      make_yaml('foo.yaml.erb', "k: <%= values[:foo] %>")
      @mixer = Kerbi::Mixer.new({foo: 'bar'})
    end

    context 'with a simplified path' do
      it 'outputs the correct list of hashes' do
        actual = @mixer.inflate_yaml_file('foo', nil, nil, {})
        expect(actual).to eq([{k: 'bar'}])
      end
    end

    context 'with an absolute path' do
      it 'outputs the correct list of hashes' do
        path = "#{root}/foo.yaml.erb"
        actual = @mixer.inflate_yaml_file(path, nil, nil, {})
        expect(actual).to eq([{k: 'bar'}])
      end
    end
  end

  # describe '#inflate_yaml_http' do
  #   it 'returns the correct list of hashes' do
  #     options = {
  #       from: 'github',
  #       project: 'nectar-cs/nectarines',
  #       file: 'wiz-ci/kerbi/values.yaml'
  #     }
  #     actual = subject.inflate_yaml_http(options, nil, nil, {})
  #     expect(actual.first&.keys.count).to eq(3)
  #   end
  # end

  describe ".locate_self" do
    it "stores and later outputs the value" do
      class Subclass < Kerbi::Mixer
        locate_self 'foo'
      end
      expect(Subclass.new({}).class.class_pwd).to eq('foo')
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

  describe "integration" do
    it 'returns the expected list of hashes' do
      result = subject.run do |r|
        r.yaml tmp_file(YAML.dump({ k1: 'v1' }))
        r.hash({k2: 'v2'})
      end
      expect(result).to eq([{k1: 'v1'}, {k2: 'v2'}])
    end
  end

end