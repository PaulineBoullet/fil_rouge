# Réattribue toutes les adresses après un changement du domaine de l'organisation.
#
# Le domaine ne sert qu'à l'identification : une adresse de ce domaine est un collaborateur,
# toute autre adresse est un correspondant rattaché à son domaine tiers. Quand le domaine
# change, on relit donc les mails déjà en base :
# 1. chaque adresse est reliée de nouveau à un collaborateur ou à un correspondant ;
# 2. les mails sans fil (repris de la V1) sont relus et rattachés à un fil ;
# 3. chaque fil reprend son domaine tiers et son premier correspondant, ou devient interne ;
# 4. les personnes et domaines tiers qui ne servent plus sont supprimés.
#
# Une personne qui change de catégorie garde sa validation (un correspondant validé devient
# un collaborateur validé, et inversement). Les fils gardent leur statut, leur catégorie,
# leur masquage et leur synthèse.
class Reidentification
  Result = Struct.new(:employees, :contacts, :conversations, keyword_init: true)

  def initialize(org_domain: Setting.org_domain)
    @org_domain = org_domain.to_s.downcase
    @resolver = AddressResolver.new(org_domain: @org_domain)
  end

  def call
    previous_states = remember_states

    ActiveRecord::Base.transaction do
      relink_participants(previous_states)
      attach_orphan_emails
      Conversation.find_each { |conversation| recompute(conversation) }
      clean_up
    end

    Result.new(employees: Employee.count, contacts: Contact.count, conversations: Conversation.count)
  end

  private

  # État de validation de chaque adresse avant le changement
  def remember_states
    states = {}
    Contact.find_each { |c| states[c.email] = c.state }
    Employee.find_each { |e| states[e.email] = e.state }
    states
  end

  def relink_participants(previous_states)
    EmailParticipant.find_each do |participant|
      person = @resolver.call(participant.address, participant.name)
      record = person[:employee] || person[:contact]
      carry_state(record, previous_states[participant.address])
      participant.update_columns(employee_id: person[:employee]&.id, contact_id: person[:contact]&.id)
    end
  end

  # Une personne qui vient de changer de catégorie garde sa validation
  def carry_state(record, previous_state)
    return if record.nil? || previous_state.nil? || !record.pending?

    if record.is_a?(Employee)
      record.validated! if previous_state == "validated"
    elsif %w[validated blocked].include?(previous_state)
      record.update!(state: previous_state)
    end
  end

  def attach_orphan_emails
    Email.where(conversation_id: nil).chronological.find_each do |email|
      EmailImporter.new(email.content, resolver: @resolver).refresh(email)
      ConversationResolver.new(email).call
    end
  end

  # Le fil appartient au domaine tiers présent au début de la conversation
  def recompute(conversation)
    first = conversation.emails.chronological.includes(:email_participants).first
    return if first.nil?

    ordered = first.email_participants.sort_by { |p| [%w[from to cc].index(p.role) || 3, p.id] }
    origin = Contact.find_by(id: ordered.map(&:contact_id).compact.first)
    origin ||= conversation.contacts.first
    conversation.update_columns(origin_contact_id: origin&.id, company_id: origin&.company_id,
                                internal: origin.nil?, updated_at: Time.current)
  end

  def clean_up
    used_contacts = EmailParticipant.where.not(contact_id: nil).select(:contact_id)
    used_employees = EmailParticipant.where.not(employee_id: nil).select(:employee_id)

    if @org_domain.present?
      # Adresses de l'organisation qui étaient des correspondants
      Contact.where("email LIKE ?", "%@#{@org_domain}").where.not(id: used_contacts).delete_all
      Company.where(domain: @org_domain).where.not(id: Contact.select(:company_id)).destroy_all
    end

    # Collaborateurs qui ne sont plus dans le domaine de l'organisation
    stale = Employee.where.not(id: used_employees)
    stale = stale.where.not("email LIKE ?", "%@#{@org_domain}") if @org_domain.present?
    stale.delete_all
  end
end
