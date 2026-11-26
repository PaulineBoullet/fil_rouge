require "test_helper"

class ReidentificationTest < ActiveSupport::TestCase
  include EmlFactory

  setup do
    Status.create!(name: "Information", rank: 1)
  end

  def import_without_domain(raw)
    EmailImporter.new(raw, resolver: AddressResolver.new(org_domain: "")).call
  end

  test "renseigner le domaine après l'import transforme les adresses de l'organisation en collaborateurs" do
    import_without_domain eml(id: "a@kelenn.test", from: "Camille TANGUY <camille@kelenn.test>", to: "claire@morvan.fr", subject: "Facture")
    assert_equal 0, Employee.count
    assert Company.exists?(domain: "kelenn.test")
    Contact.find_by!(email: "camille@kelenn.test").validated!

    Reidentification.new(org_domain: "kelenn.test").call

    camille = Employee.find_by!(email: "camille@kelenn.test")
    assert camille.validated?, "la validation est conservée"
    assert_not Contact.exists?(email: "camille@kelenn.test")
    assert_not Company.exists?(domain: "kelenn.test")

    conversation = Conversation.first
    assert_equal "claire@morvan.fr", conversation.origin_contact.email
    assert_equal "morvan.fr", conversation.company.domain
  end

  test "retirer le domaine transforme les collaborateurs en correspondants" do
    import eml(id: "a@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "Facture")
    assert Employee.exists?(email: "camille@kelenn.test")

    Reidentification.new(org_domain: "").call

    assert_equal 0, Employee.count
    assert Contact.exists?(email: "camille@kelenn.test")
    assert_equal "camille@kelenn.test", Conversation.first.origin_contact.email
  end

  test "les mails repris sans fil sont rattachés à un fil" do
    import eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Facture")
    Email.update_all(conversation_id: nil)
    Conversation.delete_all

    Reidentification.new(org_domain: "kelenn.test").call

    assert_equal 1, Conversation.count
    assert_equal 1, Conversation.first.emails.count
  end
end
