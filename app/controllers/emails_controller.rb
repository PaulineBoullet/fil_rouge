class EmailsController < ApplicationController
  def analyze
    @email = Email.find(params[:id])

    EmailAnalysisService.new(@email).call

    redirect_back fallback_location: root_path,
                  notice: "Email analysé avec succès."
  end
end
