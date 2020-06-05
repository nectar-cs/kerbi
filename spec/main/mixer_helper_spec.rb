require_relative './../spec_helper'
require_relative './../../lib/main/xer_helper'

RSpec.describe Kerbi::MixerHelper do

  subject do
    class Demo
      include Kerbi::MixerHelper
    end.new
  end

  describe '#secrefy' do
    it 'returns the base64 encoding' do
      expect(subject.b64_encode_secret('demo')).to eq("ZGVtbw==\n")
    end
  end
end