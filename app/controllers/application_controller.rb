class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Après un enregistrement depuis la fenêtre modale, la redirection est d'abord
  # chargée dans le cadre Turbo, puis la page entière est rechargée : on conserve
  # le message flash pour qu'il s'affiche sur cette deuxième requête.
  before_action :keep_flash_for_frames

  protected

  def after_sign_in_path_for(_resource)
    root_path
  end

  private

  def keep_flash_for_frames
    flash.keep if turbo_frame_request?
  end

  # Motif de recherche pour ILIKE, ou nil si le champ est vide
  def search_pattern(value = params[:query])
    return if value.blank?

    "%#{ActiveRecord::Base.sanitize_sql_like(value.strip)}%"
  end
end
