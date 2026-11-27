# Liste des échanges jour par jour, du plus récent au plus ancien, par paquets de
# quelques jours (défilement vers l'historique).
#
#   feed = ActivityFeed.new(conversations: Conversation.displayable, before: Date.new(2026, 11, 24))
#   feed.dates       # les jours de ce paquet, du plus récent au plus ancien
#   feed.next_before # le jour à partir duquel charger le paquet suivant, ou nil
#   feed.emails_on(date)
class ActivityFeed
  DAYS_PER_PAGE = 5

  attr_reader :before

  def initialize(conversations:, before: nil, days: DAYS_PER_PAGE)
    @conversations = conversations
    @before = before
    @days = days
  end

  # Expression SQL du jour d'un mail, dans le fuseau de l'application
  def self.day_sql
    zone = ActiveRecord::Base.connection.quote(Time.zone.tzinfo.name)
    "DATE((emails.sent_at AT TIME ZONE 'UTC') AT TIME ZONE #{zone})"
  end

  def emails
    @emails ||= Email.where(conversation_id: @conversations.select(:id)).where.not(sent_at: nil)
  end

  def dates
    @dates ||= begin
      scope = before ? emails.where("#{self.class.day_sql} < ?", before) : emails
      scope.group(Arel.sql(self.class.day_sql))
           .order(Arel.sql("#{self.class.day_sql} DESC"))
           .limit(@days)
           .pluck(Arel.sql(self.class.day_sql))
    end
  end

  def next_before
    return if dates.empty?

    dates.last if emails.where("#{self.class.day_sql} < ?", dates.last).exists?
  end

  def empty?
    dates.empty?
  end

  def emails_on(date)
    emails_by_date.fetch(date, [])
  end

  # Dernier jour d'échange de chaque domaine tiers (pour griser les cartes qui réapparaissent plus haut)
  def latest_day_by_company
    @latest_day_by_company ||= emails.joins(:conversation).group("conversations.company_id")
                                     .maximum(Arel.sql(self.class.day_sql))
  end

  # Dernier jour d'échange de chaque fil
  def latest_day_by_conversation
    @latest_day_by_conversation ||= emails.group(:conversation_id).maximum(Arel.sql(self.class.day_sql))
  end

  private

  def emails_by_date
    @emails_by_date ||= emails.where("#{self.class.day_sql} IN (?)", dates)
                              .includes(email_participants: %i[contact employee],
                                        conversation: %i[status category company])
                              .to_a
                              .group_by(&:day)
  end
end
