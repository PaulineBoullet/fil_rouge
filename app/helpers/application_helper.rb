module ApplicationHelper
  # Lien du menu latéral, surligné quand il correspond à la page affichée
  def sidebar_link(label, path, icon: nil, active: false, sub: false)
    classes = ["sidebar-link"]
    classes << "sidebar-link--sub" if sub
    classes << "active" if active
    options = { class: classes.join(" ") }
    options[:aria] = { current: "page" } if active

    link_to path, options do
      safe_join([
        (tag.i(class: "fa-solid #{icon}", aria: { hidden: true }) if icon),
        tag.span(label)
      ].compact)
    end
  end

  # Le dashboard et les pages qu'on ouvre depuis ses cartes
  def consultation_page?
    controller_name == "pages" ||
      (%w[companies contacts].include?(controller_name) && action_name == "show")
  end

  # Une rubrique des paramètres (liste et formulaires)
  def settings_page?(name)
    controller_name == name && action_name != "show"
  end
end
