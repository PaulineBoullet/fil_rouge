# Dashboard pour un jour : les domaines tiers qui ont échangé ce jour-là, classés selon le
# statut le plus urgent de leurs fils, et pour chacun les cartes de ses fils du jour.
class DashboardCards
  Group = Struct.new(:company, :conversation_cards, :top_status, :summary, :later_day, keyword_init: true) do
    def stale? = later_day.present?
    def internal? = company.nil?
    def name = company&.name || "Fils internes"
    def conversations = conversation_cards.map(&:conversation)
  end

  def initialize(feed)
    @feed = feed
  end

  def for(date)
    emails = @feed.emails_on(date)
    summaries = summaries_for(date, emails)

    emails.group_by { |e| e.conversation.company }.map do |company, company_emails|
      cards = conversation_cards(company_emails, date)
      latest = @feed.latest_day_by_company[company&.id]
      Group.new(
        company: company,
        conversation_cards: cards,
        top_status: cards.filter_map(&:status).min_by(&:rank),
        summary: company && summaries[company.id],
        later_day: latest && latest > date ? latest : nil
      )
    end.sort_by { |group| [group.top_status&.rank || Float::INFINITY, group.name.downcase] }
  end

  private

  def conversation_cards(emails, date)
    emails.group_by(&:conversation).map do |conversation, conversation_emails|
      latest = @feed.latest_day_by_conversation[conversation.id]
      ConversationCards::Card.new(
        conversation: conversation,
        emails_count: conversation_emails.size,
        people: conversation_emails.flat_map(&:email_participants).filter_map(&:contact).uniq,
        later_day: latest && latest > date ? latest : nil
      )
    end.sort_by { |card| [card.conversation.priority_rank, card.conversation.display_title.downcase] }
  end

  def summaries_for(date, emails)
    ids = emails.filter_map { |e| e.conversation.company_id }.uniq
    CompanySummary.where(company_id: ids, day: date).index_by(&:company_id)
  end
end
