require "test_helper"

# Report sur le fil de la catégorie et du statut proposés par l'IA pour ses mails.
class ConversationClassifierTest < ActiveSupport::TestCase
  include EmlFactory

  setup do
    Setting.create!(org_domain: "kelenn.test")
    @urgent = Status.create!(name: "Urgent", rank: 1)
    @info = Status.create!(name: "Information", rank: 2)
    @facturation = Category.create!(name: "Facturation")
    @paie = Category.create!(name: "Budget et paie")

    import eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Facture",
               date: "Mon, 23 Nov 2026 09:00:00 +0100")
    import eml(id: "b@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "RE: Facture",
               in_reply_to: "a@morvan.fr", date: "Tue, 24 Nov 2026 09:00:00 +0100")
    import eml(id: "c@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "RE: Facture",
               in_reply_to: "b@kelenn.test", date: "Wed, 25 Nov 2026 09:00:00 +0100")
    @conversation = Conversation.first
  end

  def analyse(message_id, status:, category:)
    Email.find_by!(message_id: message_id)
         .update!(summary: "Synthèse", metadata: { "status" => status, "category" => category })
  end

  test "le statut du dernier mail et la catégorie la plus fréquente" do
    analyse "a@morvan.fr", status: "Urgent", category: "Facturation"
    analyse "b@kelenn.test", status: "Urgent", category: "Facturation"
    analyse "c@morvan.fr", status: "Information", category: "Budget et paie"

    ConversationClassifier.new(@conversation).call

    assert_equal @info, @conversation.reload.status
    assert_equal @facturation, @conversation.category
  end

  test "à égalité, la catégorie du mail le plus récent" do
    analyse "a@morvan.fr", status: "Urgent", category: "Facturation"
    analyse "c@morvan.fr", status: "Urgent", category: "Budget et paie"

    ConversationClassifier.new(@conversation).call

    assert_equal @paie, @conversation.reload.category
  end

  test "un nom recopié sans majuscule ni accent est reconnu" do
    analyse "c@morvan.fr", status: "urgent", category: "BUDGET ET PAIE"

    ConversationClassifier.new(@conversation).call

    assert_equal @urgent, @conversation.reload.status
    assert_equal @paie, @conversation.category
  end
end
