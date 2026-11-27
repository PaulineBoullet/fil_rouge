require "test_helper"

class DisplayDiagnosisTest < ActiveSupport::TestCase
  include EmlFactory

  setup do
    Setting.create!(org_domain: "kelenn.test")
    Status.create!(name: "Information", rank: 1)
    import eml(id: "a@morvan.fr", from: "claire@morvan.fr", to: "camille@kelenn.test", subject: "Facture")
  end

  def keys
    DisplayDiagnosis.new.reasons.map(&:key)
  end

  test "chaque fil non affiché est compté sous la première condition qui manque" do
    assert_equal [:company_pending], keys

    Company.find_by!(domain: "morvan.fr").validated!
    assert_equal [:contact_pending], keys

    Contact.find_by!(email: "claire@morvan.fr").blocked!
    assert_equal [:contact_blocked], keys

    Contact.find_by!(email: "claire@morvan.fr").validated!
    assert_empty keys
    assert_equal 1, Conversation.displayable.count
  end

  test "sans domaine, rien ne s'affiche et seule cette raison est donnée" do
    Company.update_all(state: "validated")
    Contact.update_all(state: "validated")
    assert_equal 1, Conversation.displayable.count

    Setting.current.update!(org_domain: "")
    assert_empty Conversation.displayable
    assert_equal [:no_domain], keys
  end

  test "signale les mails sans fil" do
    Email.update_all(conversation_id: nil)
    assert_includes keys, :orphans
  end
end
