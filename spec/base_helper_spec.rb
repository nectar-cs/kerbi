require 'main_helper'
require_relative './../lib/base_helper'

RSpec.describe Kerbi::BaseHelper do

  subject do
    class Demo
      include Kerbi::BaseHelper
    end.new
  end

  describe '#secrefy' do
    it 'returns the base64 encoding' do
      expect(subject.b64_secret_encode('demo')).to eq("ZGVtbw==\n")
    end
  end
end