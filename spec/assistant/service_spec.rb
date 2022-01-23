# frozen_string_literal: true

RSpec.describe Assistant::Service, type: :class do
  describe 'Base class has no arguments' do
    let(:empty_class) { described_class.new }

    it 'has an empty array in the inputs variable' do
      expect(empty_class.instance_variable_get(:@inputs)).to eq([])
    end

    it 'run method returns nil' do
      expect(empty_class.run.nil?).to eq(true)
    end
  end

  describe 'Base class has an argument' do
    let(:empty_class) { described_class.new('an argument') }

    it 'has an argument in the inputs variable' do
      expect(empty_class.instance_variable_get(:@inputs)).to eq(['an argument'])
    end

    it 'run method returns nil' do
      expect(empty_class.run.nil?).to eq(true)
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

      it { expect(foo_class.new.run).to eq(true) }
    end
  end
end
