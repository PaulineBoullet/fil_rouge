# Recherche plein texte simple, insensible à la casse et aux accents : « hôtel » trouve
# « Hotel les Embruns », « quemener » trouve « Quéméner ». La requête est découpée en mots ;
# chaque mot doit apparaître dans au moins une des colonnes, dans n'importe quel ordre.
class TextSearch
  ACCENTED = "àáâäãåçèéêëìíîïñòóôöõùúûüýÿœæ".freeze
  PLAIN    = "aaaaaaceeeeiiiinooooouuuuyyoa".freeze

  attr_reader :terms

  def initialize(query)
    @terms = self.class.normalize(query).split.uniq
  end

  def self.normalize(text)
    text.to_s.downcase.tr(ACCENTED, PLAIN)
  end

  # Expression SQL d'une colonne ramenée en minuscules et sans accents
  def self.sql(column)
    "translate(lower(coalesce(#{column}, '')), '#{ACCENTED}', '#{PLAIN}')"
  end

  # Condition SQL : la colonne (ou l'une des colonnes) contient :term
  def self.matching(*columns)
    "(" + columns.map { |column| "#{sql(column)} LIKE :term" }.join(" OR ") + ")"
  end

  def blank?
    terms.empty?
  end

  # Applique la recherche à une relation : chaque mot doit satisfaire la condition
  def apply(relation, condition)
    terms.reduce(relation) do |scope, term|
      scope.where(condition, term: "%#{ActiveRecord::Base.sanitize_sql_like(term)}%")
    end
  end
end
