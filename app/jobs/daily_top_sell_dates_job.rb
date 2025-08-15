class DailyTopSellDatesJob < ApplicationJob
  queue_as :default

  def perform
    reported_date = 1.day.ago.beginning_of_day

    # Query to get top sales days with proper structure
    query_results = Invoice.active
                           .select("DATE(invoice_date) AS date, SUM(total) AS total_sum")
                           .group("DATE(invoice_date)")
                           .order(Arel.sql("total_sum DESC"))
                           .limit(10)

    # Convert to array of hashes with proper keys
    top_sales_days = query_results.map do |result|
      {
        date: result.date.to_date,
        total: result.total_sum.to_f
      }
    end

    if top_sales_days.any?
      InvoiceMailer.daily_top_sales_days(reported_date, top_sales_days).deliver_later
    end
  end
end
