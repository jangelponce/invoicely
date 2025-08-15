class DailyTopInvoicesJob < ApplicationJob
  queue_as :default

  def perform
    reported_date = 1.day.ago.beginning_of_day

    invoices = InvoiceQuery.new(Invoice.active, { start_date: reported_date, end_date: reported_date.end_of_day, per_page: 10, sort: "total", direction: "desc" }).call

    if invoices.any?
      InvoiceMailer.daily_top_invoices(reported_date, invoices).deliver_now
    end
  end
end
