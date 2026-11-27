require "test_helper"

# Parcours de toutes les pages V2 avec un petit jeu de données importé.
class V2PagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include EmlFactory

  setup do
    sign_in User.create!(email: "test@filrouge.fr", password: "password")
    Setting.create!(org_domain: "kelenn.test")
    Status.create!(name: "Urgent", rank: 1, description: "Échéance proche")
    Status.create!(name: "Information", rank: 2)
    Category.create!(name: "Facturation")
    Prompt.create!(name: "Prompt par défaut", content: "Résume.", is_default: true)

    import eml(id: "a@morvan.fr", from: "Claire DUBOIS <claire@morvan.fr>", to: "Camille TANGUY <camille@kelenn.test>",
               subject: "Facture", date: 2.days.ago.rfc2822)
    import eml(id: "b@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "RE: Facture",
               in_reply_to: "a@morvan.fr", date: 1.hour.ago.rfc2822)
    Company.update_all(state: "validated")
    Contact.update_all(state: "validated")
    @conversation = Conversation.first
    @company = Company.first
  end

  test "pages de consultation" do
    get root_path
    assert_response :success
    assert_select ".company-divider__name", minimum: 1
    assert_select ".company-group .fil-card", minimum: 1
    assert_select ".crumbs__here", "Dashboard"

    get root_path(view: "lignes")
    assert_response :success
    assert_select ".row-link", minimum: 1

    get root_path(domains: [@company.id])
    assert_redirected_to company_view_path(@company)

    get company_view_path(@company)
    assert_response :success

    get conversation_path(@conversation)
    assert_response :success
    assert_select ".synth"

    email = @conversation.emails.first
    get email_path(email), headers: { "Turbo-Frame" => "mail_panel" }
    assert_response :success
    assert_select ".mail-panel"

    get search_path(q: "Fact")
    assert_response :success
  end

  test "les collaborateurs sont listés avec les domaines tiers" do
    get companies_path
    assert_response :success
    assert_select ".section-title", /Collaborateurs/
    assert_select "td", /camille@kelenn.test/
  end

  test "pages de paramètres" do
    [organization_path, companies_path, contacts_path, ai_settings_path, import_failures_path].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "le nom de l'organisation et la couleur du thème se règlent dans Mon domaine" do
    patch organization_path, params: { setting: { org_domain: "kelenn.test", org_name: "Kelenn Conseil", theme_color: "#9a5867" } }
    assert_redirected_to organization_path
    assert_equal "#9A5867", Setting.current.theme_color

    get root_path
    assert_select ".brand__org", "Kelenn Conseil"
    assert_select "body[style*='--theme: #9A5867']"
    assert_select "link[rel=icon][href*='9A5867']"

    get brand_icon_path(v: "9A5867")
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "modifier le statut d'un fil le verrouille" do
    urgent = Status.find_by!(name: "Urgent")
    patch conversation_path(@conversation), params: { conversation: { status_id: urgent.id } }
    assert_redirected_to conversation_path(@conversation)
    assert @conversation.reload.status_locked?
    assert_equal urgent, @conversation.status
  end
end
