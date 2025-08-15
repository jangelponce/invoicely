class DailyTopSellDatesJob < ApplicationJob
  queue_as :default

  def perform
    reported_date = 1.day.ago.beginning_of_day

    top_sales_days = Invoice.active
                            .select("DATE(invoice_date) AS date, SUM(total) AS total_sum")
                            .group("DATE(invoice_date)")
                            .order(Arel.sql("total_sum DESC"))
                            .limit(10)

    if top_sales_days.any?
      InvoiceMailer.daily_top_sales_days(reported_date, top_sales_days).deliver_now
    end
  end
end
