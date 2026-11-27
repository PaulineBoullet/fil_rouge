module NavigationHelper
  ICONS = {
    dashboard: '<path d="M4 4h7v7H4zM13 4h7v4h-7zM13 10h7v10h-7zM4 13h7v7H4z"></path>',
    organization: '<path d="M3 21h18M5 21V8l7-4 7 4v13"></path><path d="M9 21v-5h6v5M9 11h.01M15 11h.01"></path>',
    employees: '<circle cx="9" cy="8" r="3.2"></circle><path d="M3 20c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5"></path><path d="M16 4.6a3.2 3.2 0 0 1 0 6.3M18 14.8c1.9.6 3 2.4 3 5.2"></path>',
    companies: '<circle cx="12" cy="12" r="9"></circle><path d="M3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3z"></path>',
    contacts: '<rect x="3" y="4" width="18" height="16" rx="2"></rect><circle cx="9" cy="11" r="2.4"></circle><path d="M5.5 17c.6-1.8 1.9-2.8 3.5-2.8s2.9 1 3.5 2.8M15 10h3M15 14h3"></path>',
    ai: '<path d="M4 6h9M17 6h3M4 12h3M11 12h9M4 18h11M19 18h1"></path><circle cx="15" cy="6" r="2"></circle><circle cx="9" cy="12" r="2"></circle><circle cx="17" cy="18" r="2"></circle>',
    errors: '<path d="M12 4 2.8 19.5h18.4z"></path><path d="M12 10v4.5M12 17.2h.01"></path>',
    logout: '<path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 16l-4-4 4-4M6 12h10"></path>',
    search: '<circle cx="11" cy="11" r="7"></circle><path d="m20 20-3.5-3.5"></path>',
    filter: '<path d="M3 5h18l-7 8v6l-4-2v-4z"></path>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="2"></rect><path d="M3 10h18M8 3v4M16 3v4"></path>',
    clip: '<path d="M21 12.5 12.6 21a5 5 0 0 1-7.1-7.1l9-9a3.3 3.3 0 0 1 4.7 4.7l-9 9a1.7 1.7 0 0 1-2.4-2.4l8.3-8.3"></path>',
    eye_off: '<path d="M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.1A9.8 9.8 0 0 1 12 5c5 0 9 4.5 10 7a11.6 11.6 0 0 1-3 4.2M6.1 6.1A11.8 11.8 0 0 0 2 12c1 2.5 5 7 10 7a9.7 9.7 0 0 0 4.4-1"></path>',
    close: '<path d="M6 6l12 12M18 6 6 18"></path>'
  }.freeze

  def icon(name, size: 20)
    tag.svg(ICONS.fetch(name).html_safe, width: size, height: size, viewBox: "0 0 24 24", fill: "none",
                                         stroke: "currentColor", "stroke-width": 1.9, "stroke-linecap": "round",
                                         "stroke-linejoin": "round", aria: { hidden: true })
  end

  # Lien du rail d'icônes, avec infobulle et compteur facultatif
  def rail_link(label, path, icon_name, active: false, count: nil, alert: false, method: nil)
    count_tag = count.to_i.positive? ? tag.span(count, class: ["rail-link__count", ("rail-link__count--alert" if alert)], aria: { hidden: true }) : nil
    aria_label = count.to_i.positive? ? "#{label} (#{count} à traiter)" : label
    content = safe_join([icon(icon_name), count_tag, tag.span(label, class: "rail-link__tip", aria: { hidden: true })].compact)
    options = { class: "rail-link", aria: { label: aria_label, current: (active ? "page" : nil) }.compact }

    if method
      button_to(path, method: method, form_class: "rail-link__form", **options) { content }
    else
      link_to(path, **options) { content }
    end
  end

  # Compteurs du rail : ce qui attend une action dans les paramètres
  def pending_counts
    @pending_counts ||= {
      companies: Company.pending.count,
      contacts: Contact.pending.joins(:company).merge(Company.validated).count,
      errors: ImportFailure.count
    }
  end

  def consultation_page?
    controller_name.in?(%w[pages conversations emails search]) ||
      (controller_name == "companies" && action_name == "show")
  end

  # Fil d'Ariane de hauteur fixe : « Dashboard / » reste au même endroit à tous les niveaux
  def breadcrumb(*items, title: nil)
    parts = []
    if title.nil? && items.empty?
      parts << tag.h1("Dashboard", class: "crumbs__here")
      parts << tag.span("/", class: "crumbs__sep", aria: { hidden: true })
    else
      ([["Dashboard", root_path]] + items).each do |label, path|
        parts << link_to(label, path, class: "crumbs__link")
        parts << tag.span("/", class: "crumbs__sep", aria: { hidden: true })
      end
      parts << tag.h1(title, class: "crumbs__title")
    end
    tag.nav(safe_join(parts), class: "crumbs", aria: { label: "Fil d'Ariane" })
  end
end
