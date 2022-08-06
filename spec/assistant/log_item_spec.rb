# frozen_string_literal: true

RSpec.describe Assistant::LogItem, type: :class do
  subject { described_class.new(params) }

  describe 'invalid' do
    let(:params) { { level: '', source: '', detail: '', message: '' } }

    it { is_expected.not_to be_valid }

    it { is_expected.not_to be_valid_level }
    it { is_expected.not_to be_valid_source }
    it { is_expected.not_to be_valid_detail }
    it { is_expected.not_to be_valid_message }
  end

  describe '#valid?' do
    context 'when LogItem is info' do
      let(:params) { { level: 'info', source: 'test', detail: 'other test', message: 'This is a test' } }

      it { is_expected.to be_valid }
      it { is_expected.to be_valid_level }
      it { is_expected.to be_info }
      it { is_expected.not_to be_warning }
      it { is_expected.not_to be_error }
    end

    context 'when LogItem is warning' do
      let(:params) { { level: 'warning', source: 'test', detail: 'other test', message: 'This is a test' } }

      it { is_expected.to be_valid }
      it { is_expected.to be_valid_level }
      it { is_expected.to be_warning }
      it { is_expected.not_to be_info }
      it { is_expected.not_to be_error }
    end

    context 'when LogItem is error' do
      let(:params) { { level: 'error', source: 'test', detail: 'other test', message: 'This is a test' } }

      it { is_expected.to be_valid }
      it { is_expected.to be_valid_level }
      it { is_expected.to be_error }
      it { is_expected.not_to be_info }
      it { is_expected.not_to be_warning }
    end
  end
end
