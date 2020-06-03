require_relative './../../lib/templates/service'

RSpec.describe Kerbi::ServiceTemplate do

  subject { Kerbi::ServiceTemplate }

  describe ".generic" do
    context 'with minimum params' do
      it 'injects and defaults' do
        actual = subject.generic(
          type: 'NodePort',
          ports: [ subject.port(8080) ]
        )
        expect(actual[:spec][:type]).to eq('NodePort')
      end
    end
  end

end