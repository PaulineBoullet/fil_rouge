# Cartes de la vue d'un domaine tiers pour un jour : une carte par fil actif ce jour-là.
class ConversationCards
  Card = Struct.new(:conversation, :emails_count, :people, :later_day, keyword_init: true) do
    def stale? = later_day.present?
    def status = conversation.status
  end

  def initialize(feed)
    @feed = feed
  end

  def for(date)
    @feed.emails_on(date).group_by(&:conversation).map do |conversation, emails|
      latest = @feed.latest_day_by_conversation[conversation.id]
      Card.new(
        conversation: conversation,
        emails_count: emails.size,
        people: emails.flat_map(&:email_participants).filter_map(&:contact).uniq,
        later_day: latest && latest > date ? latest : nil
      )
    end.sort_by { |card| [card.conversation.priority_rank, card.conversation.display_title.downcase] }
  end
end
