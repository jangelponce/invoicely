class InvoiceQuery
  def initialize(scope = Invoice.all, params = {})
    @scope = scope
    @params = sanitize_params(params)
  end

  def call
    @scope = filter_by_range(@scope, start_range: @params[:start_range], end_range: @params[:end_range])
    @scope = paginate(@scope, page: @params[:page], per_page: @params[:per_page])
    @scope = order(@scope, sort: @params[:sort], direction: @params[:direction])

    @scope
  end

  private

  def sanitize_params(params)
    {
      start_range: params[:start_range] && Date.parse(params[:start_range]),
      end_range: params[:end_range] && Date.parse(params[:end_range]),
      page: params[:page] && params[:page].to_i || 1,
      per_page: params[:per_page] && params[:per_page].to_i || 10,
      sort: params[:sort] || "invoice_date",
      direction: params[:direction] || "desc"
    }
  end

  def filter_by_range(scope, start_range: nil, end_range: nil)
    return scope if start_range.blank? && end_range.blank?

    scope.where(invoice_date: start_range..end_range)
  end

  def paginate(scope, page: 1, per_page: 10)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def order(scope, sort: "invoice_date", direction: "desc")
    scope.order(sort => direction)
  end
end
