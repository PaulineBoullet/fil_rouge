module ApplicationHelper
  # Libellé d'un jour dans la liste : « Aujourd'hui », « Hier », sinon le jour de la semaine
  def day_label(date)
    return "Date inconnue" if date.nil?
    return "Aujourd'hui" if date == Date.current
    return "Hier" if date == Date.yesterday
    return l(date, format: "%A").capitalize if date > Date.current - 7

    l(date, format: "%-d %B %Y").capitalize
  end

  # Précision après le libellé : « jeudi 26 novembre » après « Aujourd'hui »,
  # « 24 novembre » après « Mardi », rien après une date complète
  def day_detail(date)
    return if date.nil?
    return l(date, format: "%A %-d %B") if date >= Date.yesterday
    return l(date, format: "%-d %B") if date > Date.current - 7

    nil
  end

  # « suite aujourd'hui », « suite hier », « suite le 24 novembre »
  def later_label(date)
    return "suite aujourd'hui" if date == Date.current
    return "suite hier" if date == Date.yesterday

    "suite le #{l(date, format: '%-d %B')}"
  end

  # Gommette de statut : la couleur dépend du rang (1 = le plus urgent)
  def status_sticker(status)
    return "".html_safe if status.nil?

    tone = [status.rank.to_i, 4].min.clamp(1, 4)
    tag.span(class: ["sticker", "sticker--#{tone}"]) do
      safe_join([tag.span(class: "sticker__dot", aria: { hidden: true }), status.name])
    end
  end

  # Avatar à initiales sur fond pastel
  def initials_avatar(person, size: 26)
    name = person.respond_to?(:name) ? person.name : person.to_s
    initials = person.respond_to?(:initials) ? person.initials : name.to_s.first(2).upcase
    tone = name.to_s.sum % 4
    tag.span(initials, class: "avatar-initials avatar-initials--#{tone}", role: "img", aria: { label: name },
                       style: "--size: #{size}px")
  end

  def pluralize_fr(count, singular, plural = "#{singular}s")
    "#{count} #{count.to_i == 1 ? singular : plural}"
  end
end
