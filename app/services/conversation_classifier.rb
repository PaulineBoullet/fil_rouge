# Reporte sur un fil la catégorie et le statut proposés par l'IA pour ses mails
# (réponses enregistrées dans emails.metadata par EmailAnalysisService).
#
# Règles :
# - statut    : celui du dernier mail analysé, dans l'ordre chronologique (l'état actuel du fil) ;
# - catégorie : la plus fréquente parmi les mails analysés ; à égalité, la plus récente.
# Le classement d'un fil vient uniquement de l'IA : il ne se modifie pas à la main.
class ConversationClassifier
  def initialize(conversation)
    @conversation = conversation
  end

  def call
    analyses = @conversation.emails.chronological.where.not(summary: nil).map(&:metadata)
    return if analyses.empty?

    attrs = { status: latest_status(analyses), category: most_frequent_category(analyses) }.compact
    @conversation.update!(attrs) if attrs.any?
  end

  private

  # Statut du dernier mail analysé (un nom qui n'existe plus dans les Paramètres est ignoré)
  def latest_status(analyses)
    name = analyses.filter_map { |metadata| metadata["status"] }.last
    find_by_name(Status.all, name) if name
  end

  # Catégorie la plus fréquente ; à égalité, celle du mail le plus récent
  def most_frequent_category(analyses)
    names = analyses.filter_map { |metadata| metadata["category"] }
    return if names.empty?

    counts = names.tally
    top = counts.values.max
    winner = names.reverse.find { |name| counts[name] == top }
    find_by_name(Category.all, winner)
  end

  # L'IA recopie le nom, mais peut changer une majuscule ou un accent : on compare sans eux
  def find_by_name(records, name)
    wanted = TextSearch.normalize(name).strip
    records.find { |record| TextSearch.normalize(record.name).strip == wanted }
  end
end
