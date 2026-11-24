class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Après un enregistrement depuis la fenêtre modale, la redirection est d'abord
  # chargée dans le cadre Turbo, puis la page entière est rechargée : on conserve
  # le message flash pour qu'il s'affiche sur cette deuxième requête.
  before_action :keep_flash_for_frames

  private

  def keep_flash_for_frames
    flash.keep if turbo_frame_request?
  end

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

  # Motif de recherche pour ILIKE, ou nil si le champ est vide
  def search_pattern
    return if params[:query].blank?

    "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
  end
end
