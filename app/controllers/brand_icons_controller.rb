# Favicon et icône d'écran d'accueil, dans la couleur du thème. Accessible sans connexion
# (page de connexion). L'adresse contient la couleur : quand elle change, les navigateurs
# chargent la nouvelle icône au lieu de garder l'ancienne en cache.
class BrandIconsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    expires_in 1.year, public: true
    png = BrandIcon.new(Setting.current.theme_color, rounded: params[:plein].blank?).png
    send_data png, type: "image/png", disposition: :inline, filename: "fil-rouge.png"
  end
end
