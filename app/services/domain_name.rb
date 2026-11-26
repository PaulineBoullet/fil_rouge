# Tire un nom lisible d'un nom de domaine :
#   transports-morvan.fr      → « Transports Morvan »
#   mail.clinique-des-pins.fr → « Clinique des Pins »
module DomainName
  SMALL_WORDS = %w[de des du la le les et en sur aux au d l].freeze

  def self.humanize(domain)
    labels = domain.to_s.downcase.split(".")
    base = labels.length > 1 ? labels[-2] : labels.first.to_s
    words = base.split(/[-_]+/).compact_blank
    words.each_with_index.map { |w, i| i.positive? && SMALL_WORDS.include?(w) ? w : w.capitalize }.join(" ").presence || domain.to_s
  end
end
