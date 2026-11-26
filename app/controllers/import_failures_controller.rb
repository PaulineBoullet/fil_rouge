# Paramètres – Mails en erreur : consultation seule.
class ImportFailuresController < ApplicationController
  def index
    @failures = ImportFailure.recent_first
  end
end
