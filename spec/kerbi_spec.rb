require_relative 'spec_helper'
require_relative './../lib/kerbi'

RSpec.describe 'kirby' do
  it 'exports everything' do
    expect(Kerbi::Engine)
  end
end