require_relative './../spec_helper'
require_relative './../../lib/main/engine'

RSpec.describe Kerbi::Engine do

  subject { Kerbi::Engine.new }

  describe '#config' do
    subject.config do |config|
      config.clone_into_dir = 'x'
    end
  end

  describe '#gen_yaml' do

  end

end