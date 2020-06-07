require_relative './../spec_helper'
require_relative './../../lib/utils/helm'

RSpec.describe Kerbi::Utils::Helm do

  subject { Kerbi::Utils::Helm }

  def find_res(hashes, kind, name)
    hashes.find do |hash|
      hash['kind'] == kind && hash['metadata']['name'] == name
    end
  end

  before :each do
    config.helm_exec = 'helm'
  end

  describe '.template' do
    let(:repo) { "https://kubernetes.github.io/dashboard" }
    let(:chart) { 'kubernetes-dashboard/kubernetes-dashboard' }

    before :each do
      system("helm repo add kubernetes-dashboard #{repo}")
    end

    context 'with existing chart' do
      it 'returns the templated yaml string' do
        output = subject.template(
          'kerbi',
          chart,
          { replicaCount: 99 },
          { "service.type": "LoadBalancer",  },
          nil
        )
        hashes = YAML.load_stream(output)
        svc = find_res(hashes, 'Service', "kerbi-kubernetes-dashboard")
        dep = find_res(hashes, 'Deployment', "kerbi-kubernetes-dashboard")
        expect(svc['spec']['type']).to eq('LoadBalancer')
        expect(dep['spec']['replicas'].to_s).to eq('99')
      end
    end

    it 'cleans up' do
      subject.template('kerbi', chart, {}, {}, nil)
      expect(File.exists?(config.tmp_helm_values_path)).to be_falsey
    end
  end

  describe '.encode_inline_assigns' do
    context 'when assignments are flat' do
      it 'returns the right string' do
        #noinspection SpellCheckingInspection
        actual = subject.encode_inline_assigns(
          'bar': 'bar',
          'foo.bar': 'foo.bar'
        )
        expected = "--set bar=bar --set foo.bar=foo.bar"
        expect(actual).to eq(expected)
      end
    end

    context 'when values are nested' do
      it 'raises an runtime error' do
        expect do
          subject.encode_inline_assigns('bar': { foo: 'bar'})
        end.to raise_error("Assignments must be flat")
      end
    end
  end

  describe ".make_tmp_values_file" do
    it 'creates the tmp file with yaml and returns the path' do
      path = subject.make_tmp_values_file(foo: 'bar')
      expect(YAML.load_file(path)).to eq('foo' => 'bar')
    end
  end

  describe '.del_tmp_values_file' do
    context 'when the file exists' do
      it 'delete the file' do
        path = subject.make_tmp_values_file(foo: 'bar')
        expect(File.exists?(path)).to be_truthy
        subject.del_tmp_values_file
        expect(File.exists?(path)).to be_falsey
      end
    end

    context 'when the file does not exist' do
      it 'does not raise an error' do
        subject.del_tmp_values_file
      end
    end
  end

  describe '#can_exec?' do
    context 'exec working' do
      it 'returns true' do
        config.helm_exec = 'helm'
        expect(subject.can_exec?).to eq(true)
      end
    end

    context '.exec not working' do
      it 'returns false' do
        config.helm_exec = 'not-helm'
        expect(subject.can_exec?).to eq(false)
      end
    end
  end
end
