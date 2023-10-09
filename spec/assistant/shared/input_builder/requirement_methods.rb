# frozen_string_literal: true

RSpec.shared_context 'when building requirement methods' do
  before { foo_class.run }

  context 'when service has one required argument' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: Integer, required: true

        def execute; end
      end
    end

    include_examples 'requirement_method'
  end

  context 'when service has one required argument with conditionals' do
    let(:foo_class) do
      Class.new(described_class) do
        input :one, type: Integer, required: true, if: ->(arg) { arg == 1 }

        def execute; end
      end
    end

    include_examples 'conditional_requirement_method'
  end

  context 'when service has multiple required arguments' do
    let(:foo_class) do
      Class.new(described_class) do
        inputs %i[one two three], type: Integer, required: true

        def execute; end
      end
    end

    include_examples 'requirement_methods'
  end

  context 'when service has multiple required argument with conditionals' do
    let(:foo_class) do
      Class.new(described_class) do
        inputs %i[one two three], type: Integer, required: true, if: ->(arg) { arg == 1 }

        def execute; end
      end
    end

    include_examples 'conditional_requirement_methods'
  end
end

RSpec.shared_examples 'requirement_method' do
  it 'has one attribute-generated requirement method' do
    expect(foo_class.instance_methods.include?(:valid_require_one?)).to be(true)
  end
end

RSpec.shared_examples 'conditional_requirement_method' do
  it 'has one attribute-generated requirement method' do
    expect(foo_class.instance_methods.include?(:valid_require_conditional_one?)).to be(true)
  end
end

RSpec.shared_examples 'requirement_methods' do
  it 'has one attribute-generated requirement method per argument' do
    expect(foo_class.instance_methods & %i[valid_require_one? valid_require_two? valid_require_three?])
      .to match_array(%i[valid_require_one? valid_require_two? valid_require_three?])
  end
end

RSpec.shared_examples 'conditional_requirement_methods' do
  it 'has one attribute-generated requirement method per argument' do
    conditional_methods = %i[
      valid_require_conditional_one? valid_require_conditional_two? valid_require_conditional_three?
    ]
    expect(foo_class.instance_methods & conditional_methods).to match_array(conditional_methods)
  end
end
