require_relative './../spec_helper'

RSpec.describe Kerbi::Template::EnvVar do

  subject { Kerbi::Template::EnvVar }

  describe '.generics' do
    it 'iterates over .generic' do
      subject.generics(k: 'value', k2: 'value2')
    end
  end

  describe '.generic' do
    context 'with a flat hash' do
      it 'routes correctly' do
        expect(subject).to receive(:flat_var).with('key', 'value')
        subject.generic(key: 'value')
      end
    end
    context 'with a secret hash' do
      it 'routes correctly' do
        expect(subject).to receive(:secret_var).with('key1', 'key2', 'value')
        subject.generic(key1: { secret: { key2: 'value' } })
      end
    end
    context 'with a config hash' do
      it 'routes correctly' do
        expect(subject).to receive(:config_var).with('key1', 'key2', 'value')
        subject.generic(key1: { config: { key2: 'value' } })
      end
    end
  end

  describe '.flat_var' do
    it 'outputs the correct form' do
      result = subject.flat_var('key', 'value')
      expect(result).to eq({name: 'KEY', value: 'value'})
    end
  end

  describe '.secret_var' do
    it 'outputs the correct form' do
      result = subject.secret_var('key', 'sec_name', 'sec_key', false)
      expect(result).to eq(
        name: 'KEY',
        valueFrom: {
          secretKeyRef: {
            name: 'sec_name',
            key: 'sec_key',
            optional: false
          }
        }
      )
    end
  end

  describe '.config_var' do
    it 'outputs the correct form' do
      result = subject.config_var('key', 'sec_name', 'sec_key', false)
      expect(result).to eq(
        name: 'KEY',
        valueFrom: {
          configMapRef: {
            name: 'sec_name',
            key: 'sec_key',
            optional: false
          }
        }
      )
    end
  end
end