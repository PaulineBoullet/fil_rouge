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

  test "signale l'absence de domaine et les mails sans fil" do
    Setting.current.update!(org_domain: "")
    Email.update_all(conversation_id: nil)

    assert_includes keys, :no_domain
    assert_includes keys, :orphans
  end
end
