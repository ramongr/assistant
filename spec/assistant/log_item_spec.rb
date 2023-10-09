# frozen_string_literal: true

RSpec.describe Assistant::LogItem, type: :class do
  describe 'invalid' do
    subject { build(:invalid_log_item) }

    it { is_expected.not_to be_valid }

    it { is_expected.not_to be_valid_level }
    it { is_expected.not_to be_valid_source }
    it { is_expected.not_to be_valid_detail }
    it { is_expected.not_to be_valid_message }
  end

  describe '#valid?' do
    context 'when LogItem is info' do
      subject { build(:log_item_info) }

      it { is_expected.to be_valid }
      it { is_expected.to be_valid_level }
      it { is_expected.to be_info }
      it { is_expected.not_to be_warning }
      it { is_expected.not_to be_error }
    end

    context 'when LogItem is warning' do
      subject { build(:log_item_warning) }

      it { is_expected.to be_valid }
      it { is_expected.to be_valid_level }
      it { is_expected.to be_warning }
      it { is_expected.not_to be_info }
      it { is_expected.not_to be_error }
    end

    context 'when LogItem is error' do
      subject { build(:log_item_error) }

      it { is_expected.to be_valid }
      it { is_expected.to be_valid_level }
      it { is_expected.to be_error }
      it { is_expected.not_to be_info }
      it { is_expected.not_to be_warning }
    end
  end
end
