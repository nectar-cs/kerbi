require 'spec_helper'
require_relative './../lib/val_man'

RSpec.describe Kerbi::ValMan do

  subject { Kerbi::ValMan }

  describe ".str_assign_to_h" do
    it "returns the right hash" do
      result = subject.str_assign_to_h("foo.bar:baz")
      expect(result).to eq({foo: {bar: 'baz'}})
    end
  end

  describe ".read_arg_values" do
    context "when --set flags are passed" do
      it "returns a merged hash" do
        ARGV.replace %w[--set foo:bar --set x:y]
        actual = subject.read_arg_assignments
        expect(actual).to eq(foo: 'bar', x: 'y')
      end
    end
  end

  describe ".value_paths" do
    it "produces the correct filename" do
      result = subject.values_paths('foo')
      expected = [
        'foo',
        'values/foo',
        'values/foo.yaml.erb',
        'values/foo.yaml',
        'foo.yaml.erb',
        'foo.yaml',
      ]
      expect(result).to match_array(expected)
    end
  end

  describe ".arg_value" do
    context 'when the arg is present' do
      context 'and the value is too' do
        it 'outputs the following value' do
          ARGV.replace %w[-foo bar]
          expect(subject.arg_value('-foo')).to eq('bar')
        end
      end
      context 'but the value is not' do
        it 'outputs nil' do
          ARGV.replace %w[-foo]
          expect(subject.arg_value('-foo')).to be_nil
        end
      end
    end

    context 'when the arg is missing' do
      it 'returns nil' do
        ARGV.replace %w[-foo]
        expect(subject.arg_value('-bar')).to be_nil
      end
    end
  end

  describe '.arg_values' do
    it 'returns the expected arg values' do
      ARGV.replace %w[-foo bar -foo baz]
      expect(subject.arg_values('-foo')).to match_array(%w[bar baz])
    end
  end

  describe '.run_env' do
    context 'without CLI args or env' do
      it "returns 'development'" do
        expect(subject.run_env).to eq('development')
      end
    end

    context 'with only a CLI arg' do
      it 'returns the CLI value' do
        ARGV.replace %w[-e foo]
        expect(subject.run_env).to eq('foo')
      end
    end

    context 'with an env only' do
      it 'returns the env value' do
        ENV['NECTAR_K8S_ENV'] = 'foo'
        expect(subject.run_env).to eq('foo')
      end
    end

    context 'with env and CLI args' do
      it 'gives precedence to the cli arg' do
        ENV['NECTAR_K8S_ENV'] = 'foo'
        ARGV.replace %w[-e bar]
        expect(subject.run_env).to eq('bar')
      end
    end
  end

  describe '.read_values_file' do
    context 'when the file exists' do
      context 'with a helper' do
        it 'correctly interpolates using the helper' do
          path = tmp_file("foo: bar\nbaz: <%= help %>")
          output = subject.read_values_file(path, Help.new)
          expect(output[:baz]).to eq('delivered')
        end
      end

      context 'without a helper' do
        it 'correctly loads the yaml' do
          path = tmp_file("foo: bar\nbaz: bar2")
          output = subject.read_values_file(path, Help.new)
          expect(output).to eq({foo: 'bar', baz: 'bar2'})
        end
      end
    end
    context 'when the file does not exist' do
      it 'returns an empty hash' do
        output = subject.read_values_file('/bad-path', Help.new)
        expect(output).to eq({})
      end
    end
  end

  describe '.load' do
    describe "merging" do
      it 'merges correctly with nesting' do
        result = n_yaml_files(
          hashes: [
            { a: 1, b: { b: 1 } },
            { b: { b: 2, c: 3 } },
            { x: 'y1' }
          ],
          more_args: %W[--set x:y2],
          helper: nil
        )
        expect(result).to eq(a: 1, b: { b: 2, c: 3 }, x: 'y2')
      end

      it 'merges correctly with arrays' do
        result = two_yaml_files({a: [1, 2] }, {a: [3] })
        expect(result).to eq({a: [3] })
      end

      it 'merges correctly with empty hashes' do
        result = n_yaml_files(
          hashes: [
            {},
            { a: 1, b: { b: 1 } },
            {},
            { b: { b: 2, c: 3 } },
            {},
          ],
          helper: nil
        )
        expect(result).to eq({a: 1, b: { b: 2, c: 3 }})
      end
    end

    describe "helping" do
      it 'gets the correct helper values' do
        result = two_yaml_files(
          { k1: "<%= v1 %>" },
          { k2: "<%= v2 %>" },
          helper: Helper2.new
        )
        expect(result).to eq({k1: 'v1', k2: 'v2'})
      end
    end
  end
end

class Helper2
  def v1() 'v1' end
  def v2() 'v2' end
  def get_binding() binding end
end