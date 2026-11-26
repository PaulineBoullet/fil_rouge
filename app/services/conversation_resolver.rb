# Rattache un mail à son fil d'après ses en-têtes In-Reply-To et References.
# L'objet n'est pas utilisé : deux mails au même objet sans lien de réponse forment deux fils.
#
# Si le mail répond à un mail pas encore importé, il ouvre un nouveau fil. Quand le mail
# d'origine arrive, les fils qui le citent sont fusionnés dans le sien.
class ConversationResolver
  def initialize(email)
    @email = email
  end

  def call
    conversation = parent_conversation || create_conversation
    @email.update!(conversation: conversation)
    merge_orphans_into(conversation)
    conversation.refresh_from_emails!
    conversation
  end

  private

  def parent_conversation
    ids = ([@email.in_reply_to] + @email.reference_ids).compact_blank.uniq
    return if ids.empty?

    Email.where(message_id: ids).where.not(conversation_id: nil).where.not(id: @email.id)
         .chronological.first&.conversation
  end

  # Un nouveau fil appartient au domaine tiers présent au début de la conversation :
  # celui du premier correspondant (expéditeur, puis destinataires, puis copies).
  def create_conversation
    origin = origin_contact
    Conversation.create!(
      company: origin&.company,
      origin_contact: origin,
      internal: origin.nil?,
      title: Conversation.clean_subject(@email.subject),
      status: Status.default_status
    )
  end

  def origin_contact
    ordered = @email.email_participants.sort_by { |p| [%w[from to cc].index(p.role) || 3, p.id] }
    ordered.map(&:contact).compact.first
  end

  def merge_orphans_into(conversation)
    citing = Email.where("emails.in_reply_to = :id OR :id = ANY(emails.reference_ids)", id: @email.message_id)
                  .where.not(conversation_id: [nil, conversation.id])
    Conversation.where(id: citing.select(:conversation_id)).find_each do |orphan|
      orphan.emails.update_all(conversation_id: conversation.id)
      orphan.destroy!
    end
  end
end
