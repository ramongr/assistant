# frozen_string_literal: true

require_relative 'shared/input_builder/base_methods'
require_relative 'shared/input_builder/requirement_methods'
require_relative 'shared/input_builder/type_methods'
require_relative 'shared/log_list/argument_requirement_logging'
require_relative 'shared/log_list/argument_type_logging'
require_relative 'shared/log_list/error_logging'

RSpec.describe Assistant::Service, type: :class do
  shared_examples 'executes successfully' do
    before { foo_class.run }

    it 'executes successfully', :aggregate_failures do
      outcome = foo_class.run

      expect(outcome[:result]).to be(true)
      expect(outcome[:status]).to eq(:ok)
      expect(outcome[:warnings]).to eq([])
    end
  end

  shared_examples 'executes successfully with warnings' do
    before { foo_class.run }

    it 'executes successfully', :aggregate_failures do
      outcome = foo_class.run

      expect(outcome[:result]).to be(true)
      expect(outcome[:status]).to eq(:with_warnings)
      expect(outcome[:warnings].size.positive?).to be(true)
    end
  end

  shared_examples 'fails to execute successfully' do
    before { foo_class.run }

    it 'fails to execute successfully', :aggregate_failures do
      outcome = foo_class.run

      expect(outcome[:result].nil?).to be(true)
      expect(outcome[:status]).to eq(:with_errors)
      expect(outcome[:errors].size).to eq(1)
    end
  end

  describe '#log_list_module' do
    subject(:klass) { described_class.new }

    it_behaves_like 'error logging operations'
  end

  describe '#argument logging module' do
    include_context 'with proper type logging for arguments'
    include_context 'with proper requirement logging for arguments'
  end

  describe '#input builder module' do
    include_context 'when building base methods'
    include_context 'when building type checking'
    include_context 'when building requirement methods'
  end

  describe 'Base class has no arguments' do
    let(:empty_class) { described_class.new }

    it 'has an empty array in the inputs variable' do
      expect(empty_class.instance_variable_get(:@inputs)).to eq({})
    end

    it 'run method returns empty result' do
      expect(empty_class.run[:result].nil?).to be_truthy
    end
  end

  describe 'Base class is a superclass' do
    context 'when the execute method is overriden' do
      let(:foo_class) do
        Class.new(described_class) do
          def execute
            true
          end
        end
      end

      it 'has an empty array in the inputs variable' do
        expect(foo_class.new.instance_variable_get(:@inputs)).to eq({})
      end

      it { expect(foo_class.new.run).to be_truthy }
    end
  end

  describe 'Input-level validation' do
    context 'when the service has no inputs' do
      let(:foo_class) do
        Class.new(described_class) do
          def execute
            true
          end
        end
      end

      include_examples 'executes successfully'
    end

    context 'when the service has one non-required input' do
      let(:foo_class) do
        Class.new(described_class) do
          input :one, type: Integer

          def execute
            true
          end
        end
      end

      include_examples 'executes successfully'
    end

    context 'when the service has one required input' do
      let(:foo_class) do
        Class.new(described_class) do
          input :one, type: Integer, required: true

          def execute
            true
          end
        end
      end

      include_examples 'fails to execute successfully'
    end
  end

  describe 'Custom level validation' do
    context 'when there is no custom validation' do
      let(:foo_class) do
        Class.new(described_class) do
          input :one, type: Integer

          def execute
            true
          end
        end

        include_examples 'executes successfully'
      end
    end

    context 'when there is a custom validation that raises an error' do
      let(:foo_class) do
        Class.new(described_class) do
          input :one, type: Integer

          def validate
            add_log(level: :error, detail: :base_validation, source: :error, message: 'Custom validation error')
          end

          def execute
            true
          end
        end
      end

      include_examples 'fails to execute successfully'
    end

    context 'when there is a custom validation that does not raise an error' do
      let(:foo_class) do
        Class.new(described_class) do
          input :one, type: Integer

          def validate
            add_log(level: :warning, detail: :base_validation, source: :error, message: 'Custom validation error')
          end

          def execute
            true
          end
        end
      end

      include_examples 'executes successfully with warnings'
    end
  end
end
