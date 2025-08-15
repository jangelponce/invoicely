require 'rails_helper'

RSpec.describe DailyTopSellDatesJob, type: :job do
  describe '#perform' do
    let!(:invoice1) { create(:invoice, invoice_date: 1.day.ago, total: 1000.00, active: true) }
    let!(:invoice2) { create(:invoice, invoice_date: 1.day.ago, total: 500.00, active: true) }
    let!(:invoice3) { create(:invoice, invoice_date: 2.days.ago, total: 800.00, active: true) }
    let!(:invoice4) { create(:invoice, invoice_date: 3.days.ago, total: 200.00, active: false) }

    before do
      allow(InvoiceMailer).to receive(:daily_top_sales_days).and_call_original
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
    end

    it 'sends email with top sales days when invoices exist' do
      expect {
        described_class.new.perform
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(InvoiceMailer).to have_received(:daily_top_sales_days)
    end

    it 'groups invoices by date and sums totals correctly' do
      described_class.new.perform

      expect(InvoiceMailer).to have_received(:daily_top_sales_days) do |reported_date, top_sales_days|
        expect(top_sales_days).to be_an(Array)
        expect(top_sales_days.length).to be <= 10

        # El día con más ventas debería ser el de ayer (1500.00)
        top_day = top_sales_days.first
        expect(top_day[:total]).to eq(1500.00)
        expect(top_day[:date]).to eq(1.day.ago.to_date)
      end
    end

    it 'only includes active invoices' do
      described_class.new.perform

      expect(InvoiceMailer).to have_received(:daily_top_sales_days) do |reported_date, top_sales_days|
        # No debería incluir la factura inactiva del día 3
        dates = top_sales_days.map { |day| day[:date] }
        expect(dates).not_to include(3.days.ago.to_date)
      end
    end

    context 'when no active invoices exist' do
      before do
        Invoice.update_all(active: false)
      end

      it 'does not send email' do
        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)

        expect(InvoiceMailer).not_to have_received(:daily_top_sales_days)
      end
    end
  end
end
