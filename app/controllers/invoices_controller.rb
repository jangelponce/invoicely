class InvoicesController < ApplicationController
  def index
    respond_to do |format|
      format.html { render inertia: "invoices/index" }
      format.json { render json: { invoices: InvoiceQuery.new(Invoice.all, query_params).cached_call } }
    end
  end

  private

  def query_params
    params.permit(:start_range, :end_range, :page, :per_page, :sort, :direction)
  end
end
