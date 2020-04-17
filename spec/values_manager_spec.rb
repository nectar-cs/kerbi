require_relative './../values_manager'

RSpec.describe ValuesManager do

  subject { ValuesManager }


  describe ".vpath" do
    it "produces the correct filename" do
      result = subject.v_path('foo')
      expect(result).to eq('values/foo.yaml.erb')
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

  describe '.file_values' do
    context 'with a valid file and binding' do
      it 'correctly interpolates using the helper' do
        path = 'spec/mock_values.yaml.erb'
        output = subject.file_values(path, Help.new)
        expect(output[:baz]).to eq('delivered')
      end
    end
  end

  describe '.load'do
    context 'when an'
  end
end

class Help
  def help()'delivered' end
  def get_binding() binding end
end
