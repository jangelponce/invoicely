class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from TypeError, with: :bad_request
  rescue_from Date::Error, with: :bad_request

  private

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
