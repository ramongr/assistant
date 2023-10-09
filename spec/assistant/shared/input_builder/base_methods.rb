# frozen_string_literal: true

RSpec.shared_context 'when building base methods' do
  before { foo_class.run }

  context 'when service has one argument' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: Integer, required: true

        def execute; end
      end
    end

    include_examples 'getter_method'
    include_examples 'checker_method'
  end

  context 'when service has multiple arguments' do
    let(:foo_class) do
      Class.new(described_class) do
        inputs %i[one two three], type: Integer, required: true

        def execute; end
      end
    end

    include_examples 'getter_methods'
    include_examples 'checker_methods'
  end
end

RSpec.shared_examples 'checker_method' do
  it 'has one attribute-generated checker method' do
    expect(foo_class.instance_methods.include?(:one?)).to be(true)
  end
end

RSpec.shared_examples 'checker_methods' do
  it 'has one attribute-generated checker method per argument' do
    expect(foo_class.instance_methods & %i[one? two? three?]).to match_array(%i[one? two? three?])
  end
end

RSpec.shared_examples 'getter_method' do
  it 'has an attribute-generated getter method' do
    expect(foo_class.instance_methods.include?(:one)).to be(true)
  end
end

RSpec.shared_examples 'getter_methods' do
  it 'has an attribute-generated getter method per argument' do
    expect(foo_class.instance_methods & %i[one two three]).to match_array(%i[one two three])
  end
end
