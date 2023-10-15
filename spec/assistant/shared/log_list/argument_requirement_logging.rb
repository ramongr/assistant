# frozen_string_literal: true

RSpec.shared_context 'with proper requirement logging for arguments' do
  context 'when the service has no required arguments' do
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
  end

  context 'when the service has required arguments' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: String, required: true

        def execute
          'Hello World'
        end
      end
    end

    it 'has an error when the service does not instantiate the declared input', :aggregate_failures do
      outcome = foo_class.run
      expect(outcome[:errors].present?).to be(true)
      expect(outcome[:errors].first.message).to eq('Service is missing argument with name one')
    end

    it 'has no error when the service instantiates the declared input', :aggregate_failures do
      outcome = foo_class.run(one: 'Bye World')
      expect(outcome[:result]).to eq('Hello World')
      expect(outcome[:errors].nil?).to be(true)
    end
  end
end
