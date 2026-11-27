require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  include EmlFactory

  setup do
    Setting.create!(org_domain: "kelenn.test")
    Status.create!(name: "Information", rank: 1)
    import eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Facture")
    @conversation = Conversation.first
    @company = Company.find_by!(domain: "morvan.fr")
    @contact = Contact.find_by!(email: "claire@morvan.fr")
  end

  test "rien n'apparaît avant validation du domaine tiers et du correspondant" do
    assert_empty Conversation.displayable

    @company.validated!
    assert_empty Conversation.displayable, "le correspondant n'est pas encore validé"

    @contact.validated!
    assert_includes Conversation.displayable, @conversation
  end

  test "un correspondant bloqué fait disparaître ses fils" do
    @company.validated!
    @contact.blocked!
    assert_empty Conversation.displayable
  end

  test "un fil masqué n'apparaît qu'avec le filtre" do
    @company.validated!
    @contact.validated!
    @conversation.update!(hidden: true)

    assert_empty Conversation.displayable
    assert_includes Conversation.displayable(show_hidden: true), @conversation
  end

  test "les mails d'un collaborateur non validé sont masqués" do
    @company.validated!
    @contact.validated!
    import eml(id: "b@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "RE: Facture",
               in_reply_to: "a@morvan.fr")

    assert_equal 1, @conversation.emails.displayable.count
    Employee.find_by!(email: "camille@kelenn.test").validated!
    assert_equal 2, @conversation.emails.displayable.count
  end

  test "les fils internes n'apparaissent qu'avec le filtre" do
    import eml(id: "c@kelenn.test", from: "sarah@kelenn.test", to: "equipe@kelenn.test", subject: "Séminaire")
    Employee.update_all(state: "validated")
    internal = Conversation.find_by!(internal: true)

    assert_not_includes Conversation.displayable, internal
    assert_includes Conversation.displayable(show_internal: true), internal
  end

  test "le titre provisoire est l'objet sans RE: ni TR:" do
    assert_equal "Facture F-12", Conversation.clean_subject("RE: TR: Fwd: Facture F-12")
    assert_equal "(sans objet)", Conversation.clean_subject("  ")
  end
end
