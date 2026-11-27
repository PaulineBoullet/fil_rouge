require "test_helper"

class ThemeColorsTest < ActiveSupport::TestCase
  test "la couleur foncée reste lisible sur fond blanc et le texte s'adapte au cadre" do
    teal = ThemeColors.new("#3A908F")
    assert_equal "#FFFFFF", teal.css_variables[/--theme-on: (#\h{6})/, 1]

    yellow = ThemeColors.new("#F1CD41")
    assert_equal "#1E1E1E", yellow.css_variables[/--theme-on: (#\h{6})/, 1], "texte foncé sur un jaune clair"
  end

  test "une couleur invalide retombe sur la couleur par défaut" do
    assert_equal "#3A908F", ThemeColors.new("pas une couleur").hex
  end

  test "l'icône est un PNG de 180 pixels" do
    png = BrandIcon.new("#9A5867").png
    assert png.start_with?("\x89PNG".b)
    assert_equal [180, 180], png[16, 8].unpack("NN")
  end
end
