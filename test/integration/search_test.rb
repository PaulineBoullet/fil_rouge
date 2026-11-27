require "test_helper"

# Recherche de la barre du haut : sans tenir compte des accents, mot par mot, et dans les mails.
class SearchTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include EmlFactory

  setup do
    sign_in User.create!(email: "test@filrouge.fr", password: "password")
    Setting.create!(org_domain: "kelenn.test")
    import eml(id: "a@embruns.fr", from: "Gaelle LE FLOCH <gaelle@embruns.fr>", to: "Camille TANGUY <camille@kelenn.test>",
               subject: "Saisonniers 2027", date: 2.days.ago.rfc2822)
    Company.update_all(state: "validated", name: "Hôtel les Embruns")
    Contact.update_all(state: "validated", display_name: "Gaëlle Le Floch", first_name: "Gaëlle", last_name: "Le Floch")
    Email.update_all(summary: "Prévoit huit saisonniers d'avril à septembre.")
  end

  test "sans accents, on trouve le domaine tiers, la personne et le fil" do
    get search_path(q: "hotel")
    assert_select ".search-list a", "Hôtel les Embruns"
    assert_select ".search-list a", "Saisonniers 2027"

    get search_path(q: "GAËLLE")
    assert_select ".search-list a", /Gaëlle/
  end

  test "plusieurs mots, dans n'importe quel ordre, y compris dans la synthèse d'un mail" do
    get search_path(q: "septembre embruns")
    assert_select ".search-list a", "Saisonniers 2027"

    get search_path(q: "septembre décembre")
    assert_select ".empty-state", /Aucun résultat/
  end
end
