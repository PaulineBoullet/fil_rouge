require "test_helper"

class DomainNameTest < ActiveSupport::TestCase
  test "tire un nom lisible du domaine" do
    assert_equal "Transports Morvan", DomainName.humanize("transports-morvan.fr")
    assert_equal "Clinique des Pins", DomainName.humanize("mail.clinique-des-pins.fr")
  end

  test "met en forme les noms en majuscules" do
    assert_equal "Camille Tanguy", PersonNameFormatter.call("Camille TANGUY")
    assert_equal "Dr Hélène Marchand", PersonNameFormatter.call("Dr Hélène MARCHAND")
    assert_nil PersonNameFormatter.call("claire@morvan.fr")
  end
end
