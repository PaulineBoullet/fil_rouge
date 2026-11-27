require "test_helper"

# Choix des fils que la tâche planifiée fait analyser par l'IA.
class ConversationAnalysisTest < ActiveSupport::TestCase
  include EmlFactory

  setup do
    Setting.create!(org_domain: "kelenn.test")
    import eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Facture",
               date: "Mon, 23 Nov 2026 09:00:00 +0100")
    Company.update_all(state: "validated")
    Contact.update_all(state: "validated")
    @conversation = Conversation.first
  end

  test "un fil dont un mail n'est pas analysé attend l'IA" do
    assert_includes ConversationAnalysis.pending, @conversation
  end

  test "un fil entièrement analysé n'attend plus, jusqu'au mail suivant" do
    Email.update_all(summary: "Synthèse")
    @conversation.update!(summary: "Synthèse du fil", summary_generated_at: Time.zone.parse("2026-11-23 10:00"))
    assert_not_includes ConversationAnalysis.pending, @conversation

    import eml(id: "b@kelenn.test", from: "camille@kelenn.test", to: "claire@morvan.fr", subject: "RE: Facture",
               in_reply_to: "a@morvan.fr", date: "Tue, 24 Nov 2026 09:00:00 +0100")
    assert_includes ConversationAnalysis.pending, @conversation
  end

  test "un fil d'un domaine tiers à valider n'est pas analysé" do
    Company.update_all(state: "pending")
    assert_not_includes ConversationAnalysis.pending, @conversation
  end
end
