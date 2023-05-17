# frozen_string_literal: true

RSpec.shared_examples 'Assistant::Utilities::InputAccess' do
  before do
    klass.run(params)
  end

  describe '#create_reader_methods' do
    context 'with one inupt argument' do
      let(:params) { { test_attribute: true } }

      it 'adds a method to private instance method list' do
        expect(klass.instance_methods.include?(:test_attribute)).to be(true)
      end
    end

    context 'with multiple inupt arguments' do
      let(:params) { { first_test_attribute: true, second_test_attribute: false } }

      it 'adds a method to private instance method list' do
        expect(klass.instance_methods & %i[first_test_attribute second_test_attribute]).not_to be([])
      end
    end
  end

  describe '#create_presence_methods' do
    context 'with one inupt argument' do
      let(:params) { { test_attribute: true } }

      it 'adds a method to private instance method list' do
        expect(klass.instance_methods.include?(:test_attribute_present?)).to be(true)
      end
    end

    context 'with multiple inupt arguments' do
      let(:params) { { first_test_attribute: true, second_test_attribute: false } }

      it 'adds a method to private instance method list' do
        expect(klass.instance_methods & %i[first_test_attribute second_test_attribute]).not_to be([])
      end
    end
  end
end
