require 'rails_helper'

RSpec.describe DailyTopInvoicesJob, type: :job do
  describe '#perform' do
    let(:reported_date) { 1.day.ago.beginning_of_day }
    let!(:invoice1) { create(:invoice, invoice_date: reported_date + 2.hours, total: 1000.00, active: true) }
    let!(:invoice2) { create(:invoice, invoice_date: reported_date + 4.hours, total: 1500.00, active: true) }
    let!(:invoice3) { create(:invoice, invoice_date: reported_date + 6.hours, total: 800.00, active: true) }
    let!(:invoice4) { create(:invoice, invoice_date: reported_date + 8.hours, total: 200.00, active: false) }
    let!(:invoice5) { create(:invoice, invoice_date: 2.days.ago, total: 2000.00, active: true) }

    before do
      allow(InvoiceMailer).to receive(:daily_top_invoices).and_call_original
    end

    it 'sends email with top invoices when active invoices exist for the reported date' do
      expect {
        described_class.new.perform
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(InvoiceMailer).to have_received(:daily_top_invoices).with(reported_date, anything)
    end

    it 'queries invoices for the correct date range' do
      described_class.new.perform

      expect(InvoiceMailer).to have_received(:daily_top_invoices) do |date, invoices|
        expect(date).to eq(reported_date)
        expect(invoices).to be_an(Array)

        invoice_dates = invoices.map(&:invoice_date).map(&:to_date).uniq
        expect(invoice_dates).to all(eq(reported_date.to_date))
      end
    end

    it 'orders invoices by total amount in descending order' do
      described_class.new.perform

      expect(InvoiceMailer).to have_received(:daily_top_invoices) do |date, invoices|
        totals = invoices.map(&:total)
        expect(totals).to eq(totals.sort.reverse)

        expect(invoices.first.total).to eq(1500.00)
      end
    end

    it 'limits results to 10 invoices' do
      11.times do |i|
        create(:invoice, invoice_date: reported_date + i.minutes, total: (i + 1) * 100, active: true)
      end

      described_class.new.perform

      expect(InvoiceMailer).to have_received(:daily_top_invoices) do |date, invoices|
        expect(invoices.count).to eq(10)
      end
    end

    it 'only includes active invoices' do
      described_class.new.perform

      expect(InvoiceMailer).to have_received(:daily_top_invoices) do |date, invoices|
        expect(invoices.all?(&:active)).to be true

        invoice_ids = invoices.map(&:id)
        expect(invoice_ids).not_to include(invoice4.id)
      end
    end

    context 'when no active invoices exist for the reported date' do
      before do
        Invoice.where(invoice_date: reported_date..reported_date.end_of_day).update_all(active: false)
      end

      it 'does not send email' do
        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)

        expect(InvoiceMailer).not_to have_received(:daily_top_invoices)
      end
    end

    context 'when no invoices exist at all' do
      before do
        Invoice.delete_all
      end

      it 'does not send email' do
        expect {
          described_class.new.perform
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)

        expect(InvoiceMailer).not_to have_received(:daily_top_invoices)
      end
    end

    it 'uses InvoiceQuery with correct parameters' do
      allow(InvoiceQuery).to receive(:new).and_call_original

      described_class.new.perform

      expect(InvoiceQuery).to have_received(:new).with(
        Invoice.active,
        hash_including(
          start_range: reported_date.to_s,
          end_range: reported_date.end_of_day.to_s,
          per_page: 10,
          sort: "total",
          direction: "desc"
        )
      )
    end
  end
end
