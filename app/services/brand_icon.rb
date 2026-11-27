require "zlib"

# Icône de Fil rouge (favicon, icône d'écran d'accueil) dans la couleur du thème :
# le fil blanc, dessiné à partir d'un masque 180 × 180 en niveaux de gris, posé sur un carré
# arrondi de la couleur du thème. Le PNG est écrit à la main (Zlib), sans bibliothèque d'image.
class BrandIcon
  SIZE = 180
  MASK = Rails.root.join("lib/brand/fil-rouge-fil-180.gray")
  RADIUS = SIZE * 0.22

  # rounded: false pour l'icône d'écran d'accueil d'iOS, qui arrondit les angles elle-même
  def initialize(color, rounded: true)
    @color = ThemeColors.new(color).dark
    @rounded = rounded
  end

  def png
    mask = File.binread(MASK).bytes
    r, g, b = @color
    raw = +"".b
    SIZE.times do |y|
      raw << 0 # pas de filtre sur la ligne
      SIZE.times do |x|
        t = mask[y * SIZE + x] / 255.0
        alpha = @rounded ? coverage(x, y) : 1.0
        raw << [blend(r, t), blend(g, t), blend(b, t), (alpha * 255).round].pack("C4")
      end
    end

    "\x89PNG\r\n\x1A\n".b +
      chunk("IHDR", [SIZE, SIZE, 8, 6, 0, 0, 0].pack("NNC5")) +
      chunk("IDAT", Zlib::Deflate.deflate(raw)) +
      chunk("IEND", "")
  end

  private

  def blend(channel, t) = (channel + (255 - channel) * t).round

  # Part du pixel couverte par le carré arrondi (4 × 4 échantillons, pour adoucir les angles)
  def coverage(x, y)
    inside = 0
    4.times do |i|
      4.times do |j|
        inside += 1 if inside_rounded_square?(x + (i + 0.5) / 4, y + (j + 0.5) / 4)
      end
    end
    inside / 16.0
  end

  def inside_rounded_square?(px, py)
    cx = px.clamp(RADIUS, SIZE - RADIUS)
    cy = py.clamp(RADIUS, SIZE - RADIUS)
    (px - cx)**2 + (py - cy)**2 <= RADIUS**2
  end

  def chunk(type, data)
    [data.bytesize].pack("N") + type.b + data.b + [Zlib.crc32(type + data)].pack("N")
  end
end
