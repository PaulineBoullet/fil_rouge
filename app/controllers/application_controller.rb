class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Date affichée sur le dashboard et les pages entreprise et contact.
  # Sans date dans l'adresse (ou avec une date invalide), on prend
  # la dernière date pour laquelle une synthèse existe.
  def set_date
    @latest_date = CompanySummary.maximum(:generated_at)&.to_date || Date.current
    @date = parse_date(params[:date]) || @latest_date
  end

  def parse_date(value)
    Date.iso8601(value)
  rescue ArgumentError, TypeError
    nil
  end
end
