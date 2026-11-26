require "test_helper"

class StatusTest < ActiveSupport::TestCase
  test "le statut par défaut est le moins urgent, et l'ordre se modifie" do
    urgent = Status.create!(name: "Urgent", rank: 1)
    action = Status.create!(name: "En attente d'action", rank: 2)
    info = Status.create!(name: "Information", rank: 3)

    assert_equal info, Status.default_status

    info.move(:up)
    assert_equal [urgent, info, action], Status.ordered.to_a
  end

  test "un seul prompt par défaut" do
    first = Prompt.create!(name: "A", content: "a", is_default: true)
    second = Prompt.create!(name: "B", content: "b", is_default: true)

    assert_not first.reload.is_default?
    assert_equal second, Prompt.default_prompt
  end
end
