# Lecture d'un mail, dans un panneau ouvert par-dessus son fil.
class EmailsController < ApplicationController
  before_action :set_email

  def show
    # Ouverture directe (lien partagé, rechargement) : on affiche le fil avec le panneau ouvert
    return redirect_to conversation_path(@email.conversation_id, mail: @email.id) unless turbo_frame_request?

    @reader = EmlReader.new(@email)
  end

  def attachment
    attachment = EmlReader.new(@email).attachments[params[:index].to_i]
    return head :not_found unless attachment

    send_data attachment[:content], filename: attachment[:filename].presence || "piece-jointe",
                                    type: attachment[:content_type].presence || "application/octet-stream",
                                    disposition: :attachment
  end

  def analyze
    EmailAnalysisService.new(@email).call
    redirect_back_or_to conversation_path(@email.conversation_id), notice: "Mail analysé avec succès."
  rescue StandardError => e
    redirect_back_or_to conversation_path(@email.conversation_id), alert: "L'analyse a échoué : #{e.message}"
  end

  private

  def set_email
    @email = Email.find(params[:id])
  end
end
