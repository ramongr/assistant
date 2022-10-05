# frozen_string_literal: true

require './spec/assistant/examples/log_list'

RSpec.describe Assistant::Service, type: :class do
  describe '#log_list_module' do
    subject(:klass) { described_class.new }

    it_behaves_like 'Assistant::LogList'
  end

  describe 'Base class has no arguments' do
    let(:empty_class) { described_class.new }

    it 'has an empty array in the inputs variable' do
      expect(empty_class.instance_variable_get(:@inputs)).to eq([])
    end

    it 'run method returns empty result' do
      expect(empty_class.run[:result].nil?).to be_truthy
    end
  end

  describe 'Base class has an argument' do
    let(:empty_class) { described_class.new('an argument') }

    it 'has an argument in the inputs variable' do
      expect(empty_class.instance_variable_get(:@inputs)).to eq(['an argument'])
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
        expect(foo_class.new.instance_variable_get(:@inputs)).to eq([])
      end

      it { expect(foo_class.new.run).to be_truthy }
    end
  end
end
