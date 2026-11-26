# Nom affiché d'un collaborateur ou d'un correspondant : le nom saisi à la main,
# sinon celui lu dans l'en-tête des mails, sinon l'adresse.
module PersonName
  extend ActiveSupport::Concern

  def name
    display_name.presence || [first_name, last_name].compact_blank.join(" ").presence || email
  end
  alias_method :full_name, :name

  def initials
    words = name.to_s.split(/[\s@._-]+/).compact_blank
    words.first(2).map { |w| w[0] }.join.upcase
  end
end
