# Un fil de conversation (le nom Thread est déjà pris par Ruby).
class Conversation < ApplicationRecord
  belongs_to :company, optional: true
  belongs_to :origin_contact, class_name: "Contact", optional: true, inverse_of: :originated_conversations
  belongs_to :category, optional: true
  belongs_to :status, optional: true
  has_many :emails, dependent: :nullify

  # Fils affichables :
  # - aucun tant que le domaine de l'organisation n'est pas renseigné ;
  # - domaine tiers validé et premier correspondant validé (ni à valider, ni bloqué) ;
  # - les fils internes seulement si on les demande ;
  # - les fils masqués seulement si on les demande ;
  # - au moins un mail.
  def self.displayable(show_hidden: false, show_internal: false)
    return none if Setting.org_domain.blank?

    external = "conversations.internal = FALSE " \
               "AND conversations.company_id IN (SELECT id FROM companies WHERE state = 'validated') " \
               "AND conversations.origin_contact_id IN (SELECT id FROM contacts WHERE state = 'validated')"
    condition = show_internal ? "(#{external}) OR conversations.internal = TRUE" : external

    relation = where(condition).where(id: Email.select(:conversation_id))
    relation = relation.where(hidden: false) unless show_hidden
    relation
  end

  # Titre provisoire, en attendant l'IA : l'objet du premier mail sans « RE: », « TR: », « Fwd: »
  def self.clean_subject(subject)
    text = subject.to_s.strip
    text = text.sub(/\A\s*(re|tr|fwd?|réf|ref)\s*:\s*/i, "") while text.match?(/\A\s*(re|tr|fwd?|réf|ref)\s*:/i)
    text.presence || "(sans objet)"
  end

  def display_title
    title.presence || "(sans objet)"
  end

  def priority_rank
    status&.rank || Float::INFINITY
  end

  # Recalcule les dates et le titre provisoire à partir des mails du fil
  def refresh_from_emails!
    dates = emails.where.not(sent_at: nil).pluck(:sent_at)
    first = emails.chronological.first
    attrs = { first_email_at: dates.min, last_email_at: dates.max }
    attrs[:title] = self.class.clean_subject(first&.subject) if title.blank? || title_is_provisional?
    update!(attrs)
  end

  # Le titre n'a pas encore été rédigé par l'IA : il vient d'un objet de mail
  def title_is_provisional?
    emails.pluck(:subject).map { |s| self.class.clean_subject(s) }.include?(title)
  end

  def contacts
    Contact.where(id: EmailParticipant.where(email_id: emails.select(:id)).where.not(contact_id: nil).select(:contact_id))
  end

  def participants
    ids = EmailParticipant.where(email_id: emails.select(:id))
    Contact.where(id: ids.select(:contact_id)).to_a + Employee.where(id: ids.select(:employee_id)).to_a
  end
end
