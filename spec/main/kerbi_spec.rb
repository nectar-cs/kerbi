require_relative './../spec_helper'
require_relative './../../lib/main/kerbi'

RSpec.describe 'kirby' do
  it 'exports everything' do
    expect(Kerbi::App)
  end
end