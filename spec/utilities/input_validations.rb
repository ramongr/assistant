# frozen_string_literal: true

RSpec.shared_examples 'Utilities::InputValidation' do
  describe '#key' do
    let(:params) { { name: 'test' } }

    it 'checks for things' do
      expect(klass.run(params)).to be_truthy
    end
  end
end
