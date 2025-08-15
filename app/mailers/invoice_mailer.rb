class InvoiceMailer < ApplicationMailer
  def daily_top_sales_days(report_date, top_sales_days)
    @top_sales_days = top_sales_days
    @report_date = report_date

    mail(
      to: "admin@example.com",
      subject: "Top 10 días con más ventas - #{@report_date.strftime('%B %d, %Y')}"
    )
  end

  # Mantener el método anterior por compatibilidad
  def daily_top_invoices(report_date, invoices)
    @invoices = invoices
    @total_amount = invoices.sum(&:total)
    @report_date = report_date

    mail(
      to: "admin@example.com",
      subject: "Top 10 facturas del día - #{@report_date.strftime('%B %d, %Y')}"
    )
  end
end
