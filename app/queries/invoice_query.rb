class InvoiceQuery
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 10
  DEFAULT_SORT_FIELD = "invoice_date"
  DEFAULT_SORT_DIRECTION = "desc"

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
      page: params[:page] || DEFAULT_PAGE,
      per_page: params[:per_page] || DEFAULT_PER_PAGE,
      sort: params[:sort] || DEFAULT_SORT_FIELD,
      direction: params[:direction] || DEFAULT_SORT_DIRECTION
    }
  end

  def filter_by_range(scope, start_range:, end_range:)
    return scope if start_range.blank? && end_range.blank?

    scope.where(invoice_date: start_range..end_range)
  end

  def paginate(scope, page:, per_page:)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def order(scope, sort:, direction:)
    scope.order(sort => direction)
  end
end
