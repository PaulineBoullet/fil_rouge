require "test_helper"

class EmailImporterTest < ActiveSupport::TestCase
  include EmlFactory

  setup do
    Status.create!(name: "Urgent", rank: 1)
    Status.create!(name: "Information", rank: 2)
  end

  test "un fil de trois mails est reconstitué par In-Reply-To et References" do
    import eml(id: "a@kelenn.test", from: "Camille TANGUY <camille@kelenn.test>", to: "Claire Dubois <claire@morvan.fr>", subject: "Budget 2027")
    import eml(id: "b@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "RE: Budget 2027",
               in_reply_to: "a@kelenn.test", references: ["a@kelenn.test"])
    import eml(id: "c@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "RE: RE: Budget 2027",
               in_reply_to: "b@morvan.fr", references: ["a@kelenn.test", "b@morvan.fr"])

    assert_equal 1, Conversation.count
    conversation = Conversation.first
    assert_equal 3, conversation.emails.count
    assert_equal "Budget 2027", conversation.title
    assert_equal "Morvan", conversation.company.name
    assert_equal "claire@morvan.fr", conversation.origin_contact.email
    assert_equal "Information", conversation.status.name
    assert_not conversation.internal?
  end

  test "deux mails au même objet sans lien de réponse forment deux fils" do
    import eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Question")
    import eml(id: "b@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Question")

    assert_equal 2, Conversation.count
  end

  test "un mail reçu par plusieurs boîtes n'est créé qu'une fois" do
    raw = eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test, thomas@kelenn.test")
    assert_equal :imported, import(raw).status
    assert_equal :duplicate, import(raw).status
    assert_equal 1, Email.count
  end

  test "les adresses inconnues sont créées à valider, avec un nom tiré de l'en-tête" do
    import eml(id: "a@transports-morvan.fr", from: "Claire DUBOIS <claire@transports-morvan.fr>", to: "Camille TANGUY <camille@kelenn.test>")

    contact = Contact.find_by!(email: "claire@transports-morvan.fr")
    assert contact.pending?
    assert_equal "Claire Dubois", contact.name
    assert_equal "Transports Morvan", contact.company.name
    assert contact.company.pending?

    employee = Employee.find_by!(email: "camille@kelenn.test")
    assert_equal "Camille Tanguy", employee.name
  end

  test "un mail entre collaborateurs ouvre un fil interne" do
    import eml(id: "a@kelenn.test", from: "sarah@kelenn.test", to: "equipe@kelenn.test", subject: "Séminaire")

    conversation = Conversation.first
    assert conversation.internal?
    assert_nil conversation.company
  end

  test "un fil ouvert avant son mail d'origine est fusionné quand celui-ci arrive" do
    import eml(id: "b@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "RE: Facture",
               in_reply_to: "a@kelenn.test", references: ["a@kelenn.test"], date: "Wed, 25 Nov 2026 10:00:00 +0100")
    assert_equal 1, Conversation.count

    import eml(id: "a@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "Facture",
               date: "Tue, 24 Nov 2026 10:00:00 +0100")

    assert_equal 1, Conversation.count
    assert_equal 2, Conversation.first.emails.count
  end

  test "un fichier illisible est signalé en erreur" do
    result = import("ceci n'est pas un mail")
    assert_equal :failed, result.status
    assert_equal 0, Email.count
  end
end
