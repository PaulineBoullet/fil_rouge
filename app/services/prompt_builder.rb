# Assemble les consignes envoyées à l'IA, dans cet ordre :
#   1. Le RÔLE de l'IA           -> prompt par défaut (Paramètres → Réglages de l'IA)
#   2. Les RÈGLES du code         -> OpenaiService::EMAIL_RULES (méthode, longueur, format)
#   3. Les CATÉGORIES et STATUTS  -> Paramètres → Réglages de l'IA
#   4. Le COMPLÉMENT              -> prompt spécifique du domaine tiers (sous-niveau)
class PromptBuilder
  # Utilisé seulement si aucun prompt par défaut n'est saisi dans les Paramètres
  FALLBACK_ROLE = "Tu assistes une personne qui doit garder une vue d'ensemble " \
                  "des échanges par mail circulant dans plusieurs boîtes mail."

  # Le prompt spécifique dit quoi mettre en avant ; il ne change pas la longueur ni le format
  COMPLEMENT_HEADER = "## Consignes complémentaires pour ce domaine tiers\n" \
                      "Elles précisent ce qu'il faut mettre en avant ; elles ne changent ni la longueur " \
                      "ni le format demandés ci-dessus."

  def initialize(company = nil)
    @company = company
  end

  # Analyse d'un mail : rôle + règles avec les listes des Paramètres + complément
  def email_instructions
    rules = OpenaiService::EMAIL_RULES
              .gsub("{{categories}}", categories_text)
              .gsub("{{statuses}}", statuses_text)
    assemble(rules)
  end

  # Synthèse d'un fil ou d'une journée : rôle + règles du service + complément
  def instructions_for(rules)
    assemble(rules)
  end

  private

  def assemble(rules)
    [role, rules, complement].map { |part| part.to_s.strip }.compact_blank.join("\n\n")
  end

  # Niveau 1 : le prompt par défaut des Paramètres
  def role
    Prompt.default_prompt&.content.presence || FALLBACK_ROLE
  end

  # Niveau 2 : le prompt spécifique du domaine tiers, s'il en a un
  def complement
    specific = @company&.prompt
    return if specific.nil? || specific.is_default? || specific.content.blank?

    "#{COMPLEMENT_HEADER}\n#{specific.content}"
  end

  def categories_text
    Category.ordered.map { |c| "- #{c.name} : #{c.description}" }.join("\n").presence ||
      "Aucune catégorie définie : réponds null."
  end

  def statuses_text
    Status.ordered.map { |s| "- #{s.name} : #{s.description}" }.join("\n").presence ||
      "Aucun statut défini : réponds null."
  end
end
