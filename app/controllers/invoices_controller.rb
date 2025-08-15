class InvoicesController < ApplicationController
  def index
    respond_to do |format|
      format.html { render inertia: "invoices/index" }
      format.json { render json: { invoices: InvoiceQuery.new(Invoice.all, params).call } }
    end
  end
end
