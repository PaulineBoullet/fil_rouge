# Cartes de fils pour un jour : une carte par fil actif ce jour-là, du plus urgent au moins urgent.
# Sert à la vue d'un domaine tiers et, domaine par domaine, au dashboard.
class ConversationCards
  Card = Struct.new(:conversation, :new_count, :total_count, :participants_count, :later_day, keyword_init: true) do
    def stale? = later_day.present?
    def status = conversation.status
    def category = conversation.category
  end

  def initialize(feed)
    @feed = feed
  end

  def for(date)
    sorted(@feed.emails_on(date).group_by(&:conversation).map { |conversation, emails| card(conversation, emails, date) })
  end

  # emails : les mails de ce fil ce jour-là
  def card(conversation, emails, date)
    latest = @feed.latest_day_by_conversation[conversation.id]
    Card.new(
      conversation: conversation,
      new_count: emails.size,
      total_count: @feed.total_emails_by_conversation.fetch(conversation.id, emails.size),
      participants_count: @feed.participants_by_conversation.fetch(conversation.id, 0),
      later_day: latest && latest > date ? latest : nil
    )
  end

  def sorted(cards)
    cards.sort_by { |c| [c.conversation.priority_rank, c.conversation.display_title.downcase] }
  end
end
