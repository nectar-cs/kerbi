require_relative './../lib/kerbi'

RSpec.describe 'kirby' do
  it 'exports everything' do
    expect(Kerbi::App)
  end
end