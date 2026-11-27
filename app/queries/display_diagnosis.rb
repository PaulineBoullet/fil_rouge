# Explique pourquoi des fils ne s'affichent pas sur le dashboard.
#
# Tant que le domaine de l'organisation n'est pas renseigné, aucun fil ne s'affiche.
# Un fil ne s'affiche que si son domaine tiers et son premier correspondant sont validés,
# et s'il contient au moins un mail dont l'expéditeur n'est pas un collaborateur à valider.
# Chaque fil non affiché est compté une seule fois, sous la première condition qui manque.
class DisplayDiagnosis
  Reason = Struct.new(:key, :count, :message, :link_label, :path, keyword_init: true)

  include Rails.application.routes.url_helpers

  def reasons
    # Sans domaine, aucun fil ne s'affiche : c'est la seule raison à donner
    return @reasons ||= [domain_reason] if Setting.org_domain.blank?

    @reasons ||= [
      domain_reason,
      orphan_reason,
      count_reason(:company_pending, company_pending.count,
                   "%{n} dont le domaine tiers est à valider", "Valider les domaines tiers", companies_path),
      count_reason(:contact_pending, contact_pending.count,
                   "%{n} dont le premier correspondant est à valider", "Valider les correspondants", contacts_path(state: "pending")),
      count_reason(:contact_blocked, contact_blocked.count,
                   "%{n} dont le premier correspondant est bloqué", "Voir les correspondants bloqués", contacts_path(state: "blocked")),
      count_reason(:employee_pending, employee_pending.count,
                   "%{n} dont les mails viennent tous de collaborateurs à valider", "Valider les collaborateurs", employees_path),
      count_reason(:hidden, hidden.count,
                   "%{n} masqués à la main", "Afficher les fils masqués", root_path(hidden: "1")),
      count_reason(:internal, Conversation.where(internal: true).count,
                   "%{n} internes, entre collaborateurs", "Afficher les fils internes", root_path(internal: "1"))
    ].compact
  end

  def any?
    reasons.any?
  end

  # Fils qu'une validation ferait apparaître (hors masqués et internes)
  def awaiting_validation_count
    return 0 if Setting.org_domain.blank?

    company_pending.count + contact_pending.count + employee_pending.count
  end

  private

  def domain_reason
    return if Setting.org_domain.present?

    Reason.new(key: :no_domain,
               message: "Aucun domaine n'est renseigné : aucun mail ne s'affiche tant que le domaine de votre " \
                        "organisation n'est pas indiqué.",
               link_label: "Renseigner mon domaine", path: organization_path)
  end

  def orphan_reason
    count = Email.where(conversation_id: nil).count
    return if count.zero?

    Reason.new(key: :orphans, count: count,
               message: "#{count} #{count == 1 ? 'mail n’est rattaché' : 'mails ne sont rattachés'} à aucun fil (mails repris de la V1).",
               link_label: "Relancer l'identification", path: organization_path)
  end

  def count_reason(key, count, template, link_label, path)
    return if count.zero?

    Reason.new(key: key, count: count, message: template % { n: "#{count} #{count == 1 ? 'fil' : 'fils'}" },
               link_label: link_label, path: path)
  end

  def external
    Conversation.where(internal: false)
  end

  def company_pending
    external.where(company_id: nil).or(external.where(company_id: Company.pending.select(:id)))
  end

  def with_validated_company
    external.where(company_id: Company.validated.select(:id))
  end

  def contact_pending
    with_validated_company.where(origin_contact_id: nil)
                          .or(with_validated_company.where(origin_contact_id: Contact.pending.select(:id)))
  end

  def contact_blocked
    with_validated_company.where(origin_contact_id: Contact.blocked.select(:id))
  end

  def with_validated_contact
    with_validated_company.where(origin_contact_id: Contact.validated.select(:id))
  end

  def employee_pending
    with_validated_contact.where.not(id: Email.displayable.where.not(conversation_id: nil).select(:conversation_id))
  end

  def hidden
    with_validated_contact.where(id: Email.displayable.select(:conversation_id)).where(hidden: true)
  end
end
