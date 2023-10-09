# frozen_string_literal: true

RSpec.shared_context 'when building type checking' do
  before { foo_class.run }

  context 'when service has one argument' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: Integer, required: true

        def execute; end
      end
    end

    include_examples 'type_checker_method'
  end

  context 'when service has multiple arguments' do
    let(:foo_class) do
      Class.new(described_class) do
        inputs %i[one two three], type: Integer, required: true

        def execute; end
      end
    end

    include_examples 'type_checker_methods'
  end
end

RSpec.shared_examples 'type_checker_method' do
  it 'has one attribute-generated type validation method' do
    expect(foo_class.instance_methods.include?(:valid_type_one?)).to be(true)
  end
end

RSpec.shared_examples 'type_checker_methods' do
  it 'has an attribute-generated type validation method per argument' do
    expect(
      foo_class.instance_methods & %i[valid_type_one? valid_type_two? valid_type_three?]
    ).to match_array(%i[valid_type_one? valid_type_two? valid_type_three?])
  end
end
