# frozen_string_literal: true

require 'byebug'

RSpec.shared_context 'when defining default values' do
  subject(:outcome) { foo_class.run(**params) }

  let(:params) { {} }

  # context 'when service has one default value' do
  #   let(:foo_class) do
  #     Class.new(described_class) do
  #       input :one, type: Integer, default: 0

  #       def execute; end
  #     end
  #   end

  #   it 'has one default-value-generated check method' do
  #     expect(foo_class.instance_methods.include?(:valid_default_one?)).to be(true)
  #   end
  # end

  # context 'when service has multiple default values' do
  #   let(:foo_class) do
  #     Class.new(described_class) do
  #       input :one, type: Integer, default: 0
  #       input :option_two, type: String, default: 'test'
  #       input :three, type: TrueClass, default: false

  #       def execute; end
  #     end
  #   end

  #   it 'has default-value-generated check methods', :aggregate_failures do
  #     expect(foo_class.instance_methods.include?(:valid_default_one?)).to be(true)
  #     expect(foo_class.instance_methods.include?(:valid_default_option_two?)).to be(true)
  #     expect(foo_class.instance_methods.include?(:valid_default_three?)).to be(true)
  #   end
  # end

  # context 'with an attribute with a different value than the defaut' do
  #   let(:foo_class) do
  #     Class.new(described_class) do
  #       input :one, type: Integer, default: 0

  #       def execute
  #         one
  #       end
  #     end
  #   end

  #   let(:params) { { one: 1 } }

  #   it 'maintains the original value' do
  #     expect(outcome[:result]).to eq(1)
  #   end
  # end

  context 'with an attribute that only set the default value' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: Integer, default: 0
        input :two, type: String, default: 'test'

        def execute
          [one, two]
        end
      end
    end

    let(:params) { { one: 1 } }

    it 'maintains the original value' do
      expect(outcome[:result]).to eq([1, 'test'])
    end
  end
end
