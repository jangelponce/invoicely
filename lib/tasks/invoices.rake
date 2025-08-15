namespace :invoices do
  desc "Send daily top 10 invoices email report"
  task send_daily_top_invoices_report: :environment do
    puts "Starting daily top invoices email report..."

    begin
      DailyTopInvoicesJob.perform_now
      puts "Daily top invoices email sent successfully!"
    rescue => e
      puts "Failed to send daily top invoices email: #{e.message}"
      raise e
    end
  end

  desc "Send daily top 10 sell dates email report"
  task send_daily_top_sell_dates_report: :environment do
    puts "Starting daily top sell dates email report..."

    begin
      DailyTopSellDatesJob.perform_now
      puts "Daily top sell dates email sent successfully!"
    rescue => e
      puts "Failed to send daily top sell dates email: #{e.message}"
      raise e
    end
  end
end
