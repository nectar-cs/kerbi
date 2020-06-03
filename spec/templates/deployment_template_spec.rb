require_relative './../../lib/templates/deployment'

RSpec.describe Kerbi::DeploymentTemplate do

  subject { Kerbi::DeploymentTemplate }

  describe '#generic' do

    context 'without values' do
      it 'injects the required defaults' do
        actual = subject.generic(
          name: 'bare',
          containers: [ subject.container(image: 'image-foo') ]
        )
        expect(actual[:metadata][:name]).to eq('bare')
        expect(actual[:spec][:replicas]).to eq(1)
        containers = actual[:spec][:template][:spec][:containers]
        expect(containers.count).to eq(1)
        expect(containers.first[:image]).to eq('image-foo')
        expect(containers.first[:imagePullPolicy]).to eq('Always')
        expect(containers.first[:env]).to eq([])
      end
    end

    context 'with values' do
      it 'injects the required values' do
        actual = subject.generic(
          name: 'name-foo',
          replicas: 10,
          containers: [
            subject.container(
              name: 'container-foo',
              image: 'image-bar',
              ipp: 'ipp-foo',
              env: [{ key: 'foo', value: 'bar' }]
            )
          ]
        )
        expect(actual[:metadata][:name]).to eq('name-foo')
        expect(actual[:spec][:replicas]).to eq(10)

        containers = actual[:spec][:template][:spec][:containers]
        expect(containers.count).to eq(1)
        expect(containers.first[:name]).to eq('container-foo')
        expect(containers.first[:image]).to eq('image-bar')
        expect(containers.first[:imagePullPolicy]).to eq('ipp-foo')

        envs = containers.first[:env]
        expect(envs).to eq([{key: 'foo', value: 'bar'}])
      end
    end
  end
end