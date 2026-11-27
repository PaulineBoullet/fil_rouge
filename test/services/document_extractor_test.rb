require "test_helper"

# Lecture des pièces jointes avant leur envoi à l'IA
class DocumentExtractorTest < ActiveSupport::TestCase
  test "un fichier texte ou CSV est lu tel quel" do
    csv = { filename: "variables.csv", content: "salarié;heures\nKevin;22\n".b }
    assert_equal "salarié;heures\nKevin;22", DocumentExtractor.new(csv).extract_text
  end

  test "un format inconnu est signalé" do
    assert_match "Format non pris en charge", DocumentExtractor.new(filename: "plan.dwg", content: "x").extract_text
  end

  test "les pièces jointes des mails du seed sont lues par la gem mail" do
    path = Rails.root.join("db/seeds/emails/kelenn_conseil/demo/tm-paie_01.eml")
    email = Email.new(content: File.read(path))
    attachments = EmlReader.new(email).attachments

    assert_equal ["variables_paie_novembre.csv"], attachments.map { |a| a[:filename] }
    assert_match "Pièce jointe fictive", DocumentExtractor.new(attachments.first).extract_text
  end
end
