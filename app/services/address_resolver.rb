# Relie une adresse mail à un collaborateur (domaine de l'organisation) ou à un
# correspondant (tout autre domaine). Les personnes et domaines tiers inconnus sont
# créés « à valider », avec un nom pré-rempli depuis l'en-tête du mail.
class AddressResolver
  def initialize(org_domain: Setting.org_domain)
    @org_domain = org_domain.to_s.downcase
  end

  # Renvoie { employee: } ou { contact: }, ou {} si l'adresse est inexploitable
  def call(address, name = nil)
    address = address.to_s.strip.downcase
    return {} unless address.match?(URI::MailTo::EMAIL_REGEXP)

    domain = address.split("@", 2).last
    display_name = PersonNameFormatter.call(name)

    if @org_domain.present? && domain == @org_domain
      { employee: find_or_create(Employee, address, display_name) }
    else
      company = find_or_create_company(domain)
      { contact: find_or_create(Contact, address, display_name, company: company) }
    end
  end

  private

  def find_or_create(model, address, display_name, **attrs)
    record = model.find_or_create_by!(email: address) do |r|
      r.display_name = display_name
      attrs.each { |key, value| r.public_send("#{key}=", value) }
    end
    # Nom découvert plus tard (premier mail sans nom d'affichage)
    record.update!(display_name: display_name) if record.display_name.blank? && display_name.present? && record.first_name.blank?
    record
  end

  def find_or_create_company(domain)
    return nil unless domain.match?(Setting::DOMAIN_FORMAT)

    Company.find_or_create_by!(domain: domain) { |c| c.name = DomainName.humanize(domain) }
  end
end
