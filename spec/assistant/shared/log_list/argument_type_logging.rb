# frozen_string_literal: true

RSpec.shared_context 'with proper type logging for arguments' do
  context 'when the service has no arguments' do
    let(:foo_class) do
      Class.new(described_class) do
        def execute; end
      end
    end

    it 'has an empty array in the inputs variable' do
      expect(foo_class.run[:result].nil?).to be(true)
    end
  end

  context 'when the service has an optional typed argument' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: String

        def execute
          'Hello World'
        end
      end
    end

    it 'has no errors even if the service does not instantiate the declared input', :aggregate_failures do
      outcome = foo_class.run
      expect(outcome[:result]).to eq('Hello World')
      expect(outcome[:errors].nil?).to be(true)
    end

    it 'has no error when the declared input is the declared type', :aggregate_failures do
      outcome = foo_class.run(one: 'Bye World')
      expect(outcome[:result]).to eq('Hello World')
      expect(outcome[:errors].nil?).to be(true)
    end

    it 'has an error when the declared input does not match the declared type', :aggregate_failures do
      outcome = foo_class.run(one: 1)
      expect(outcome[:errors].present?).to be(true)
      expect(outcome[:errors].first.message).to eq('Service argument with name one is not a String but Integer')
    end
  end
end
