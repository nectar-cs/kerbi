require_relative './../spec_helper'
require_relative './../../lib/main/res_bucket'

RSpec.describe Kerbi::ResBucket do

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

end