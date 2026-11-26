# Met en forme le nom lu dans l'en-tête d'un mail : « Camille TANGUY » → « Camille Tanguy ».
# Les mots tout en majuscules sont remis en casse de titre ; les autres sont gardés tels quels.
module PersonNameFormatter
  def self.call(name)
    text = name.to_s.strip.delete('"').squish
    return nil if text.blank? || text.include?("@")

    text.split(" ").map do |word|
      word.length > 1 && word == word.upcase && word.match?(/[[:alpha:]]/) ? word.split("-").map(&:capitalize).join("-") : word
    end.join(" ")
  end
end
