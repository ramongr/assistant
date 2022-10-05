# frozen_string_literal: true

RSpec.shared_examples 'Assistant::LogList' do
  describe '#add_log' do
    context 'with empty arguments' do
      let(:params) { {} }

      it 'raises a runtime error' do
        expect { klass.add_log(params) }.to raise_error(ArgumentError)
          .with_message('missing keywords: :level, :source, :detail, :message')
      end
    end

    context 'with invalid arguments' do
      let(:params) { { level: '', source: '', detail: '', message: '' } }

      it 'adds the log' do
        expect(klass.add_log(params)).to have_exactly(1).item
      end
    end

    context 'with valid arguments' do
      let(:params) { { level: 'info', source: 'test', detail: 'other test', message: 'This is a test' } }

      it 'adds the log' do
        expect(klass.add_log(params)).to have_exactly(1).item
      end
    end
  end

  describe '#infos' do
    before do
      klass.merge_logs(build_list(:log_item_info, 3))
      klass.merge_logs(build_list(:log_item_warning, 3))
    end

    it 'has 3 info level logs' do
      expect(klass.infos).to have_exactly(3).items
    end
  end
end
