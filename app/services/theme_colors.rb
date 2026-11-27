# Déclinaisons de la couleur du thème choisie dans Mon domaine.
#
#   theme = ThemeColors.new("#3A908F")
#   theme.dark  # assez foncée pour du texte ou un bouton sur fond blanc (contraste ≥ 4,5)
#   theme.soft  # aplat très pâle
#   theme.blush # teinte claire (liserés, halos)
#   theme.on    # texte posé sur la couleur du thème : blanc, ou presque noir si la couleur est claire
class ThemeColors
  WHITE = [255, 255, 255].freeze
  BLACK = [0, 0, 0].freeze
  INK = [30, 30, 30].freeze

  attr_reader :base

  def initialize(hex)
    @base = parse(hex) || parse(Setting::DEFAULT_THEME)
  end

  def hex = to_hex(base)

  def dark
    @dark ||= (0..20).map { |i| mix(base, BLACK, i * 0.05) }.find { |c| contrast(c, WHITE) >= 4.5 } || BLACK
  end

  def soft = mix(base, WHITE, 0.9)
  def blush = mix(base, WHITE, 0.55)
  def on = contrast(WHITE, base) >= 3 ? WHITE : INK

  # Variables CSS posées sur <html> par le layout (voir _theme.scss)
  def css_variables
    {
      "--theme" => to_hex(base),
      "--theme-dark" => to_hex(dark),
      "--theme-soft" => to_hex(soft),
      "--theme-blush" => to_hex(blush),
      "--theme-on" => to_hex(on),
      "--bs-primary" => to_hex(dark),
      "--bs-primary-rgb" => dark.join(", "),
      "--bs-link-color" => to_hex(dark),
      "--bs-link-color-rgb" => dark.join(", "),
      "--bs-link-hover-color-rgb" => mix(dark, BLACK, 0.2).join(", ")
    }.map { |name, value| "#{name}: #{value}" }.join("; ")
  end

  private

  def parse(hex)
    match = hex.to_s.match(/\A#?(\h{2})(\h{2})(\h{2})\z/)
    match&.captures&.map { |c| c.to_i(16) }
  end

  def to_hex(rgb) = format("#%02X%02X%02X", *rgb)

  def mix(a, b, t) = a.zip(b).map { |x, y| (x + (y - x) * t).round }

  def luminance(rgb)
    r, g, b = rgb.map do |c|
      c /= 255.0
      c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast(a, b)
    la, lb = [luminance(a), luminance(b)].sort.reverse
    (la + 0.05) / (lb + 0.05)
  end
end
