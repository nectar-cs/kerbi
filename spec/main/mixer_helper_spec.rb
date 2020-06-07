require_relative './../spec_helper'
require_relative './../../lib/main/mixer'

RSpec.describe Kerbi::MixerHelper do

  subject { Kerbi::Mixer.new({}) }

  describe '#secrefy' do
    it 'returns the base64 encoding' do
      expect(subject.b64_encode_secret('demo')).to eq("ZGVtbw==\n")
    end
  end

  describe '#inflate_yaml_http' do
    context 'with an url' do
      it 'returns the url' do
        actual = subject.http_descriptor_to_url(url: 'abc')
        expect(actual).to eq('abc')
      end
    end

    context 'with from=github' do
      it 'generates a raw github user content url' do
        actual = subject.http_descriptor_to_url(
          from: 'github',
          project: 'foo/bar',
          file: 'path/to/file.yaml'
        )

        expected = "https://raw.githubusercontent.com"
        expected = "#{expected}/foo/bar/master/path/to/file.yaml"
        expect(actual).to eq(expected)
      end
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
        actual = subject.simple_k8s_res_id(
          kind: "Volume",
          metadata: { name: "foo" }
        )
        expect(actual).to eq('Volume:foo')
      end
    end
  end

end