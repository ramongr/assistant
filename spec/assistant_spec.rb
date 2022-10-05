# frozen_string_literal: true

RSpec.describe Assistant, type: :module do
  it 'has a version number' do
    expect(Assistant::VERSION.nil?).to be(false)
  end
end
