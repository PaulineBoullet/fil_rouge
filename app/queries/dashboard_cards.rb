# Cartes du dashboard pour un jour : une carte par domaine tiers ayant échangé ce jour-là,
# classées selon le statut le plus urgent de leurs fils.
class DashboardCards
  MAX_ROWS = 4 # fils listés sur une carte ; au-delà, un lien vers la vue du domaine tiers

  Card = Struct.new(:company, :conversations, :top_status, :contacts, :summary, :later_day, keyword_init: true) do
    def stale? = later_day.present?
    def internal? = company.nil?
    def name = company&.name || "Fils internes"
  end

  def initialize(feed)
    @feed = feed
  end

  def for(date)
    emails = @feed.emails_on(date)
    summaries = summaries_for(date, emails)

    emails.group_by { |e| e.conversation.company }.map do |company, company_emails|
      conversations = company_emails.map(&:conversation).uniq
      latest = @feed.latest_day_by_company[company&.id]
      Card.new(
        company: company,
        conversations: conversations,
        top_status: conversations.filter_map(&:status).min_by(&:rank),
        contacts: company_emails.flat_map(&:email_participants).filter_map(&:contact).select(&:validated?).uniq,
        summary: company && summaries[company.id],
        later_day: latest && latest > date ? latest : nil
      )
    end.sort_by { |card| [card.top_status&.rank || Float::INFINITY, card.name.downcase] }
  end

  private

  def summaries_for(date, emails)
    ids = emails.filter_map { |e| e.conversation.company_id }.uniq
    CompanySummary.where(company_id: ids, day: date).index_by(&:company_id)
  end
end
