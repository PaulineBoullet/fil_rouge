class EmailAnalysisService
  def initialize(email)
    @email = email
  end

  def call
    result = OpenaiService.new.analyze_email(
      analysis_content,
      instructions: company_prompt
    )

    save_summary(result)
    save_metadata(result)

    @email.summary
  end

  private

  def save_summary(result)
    @email.update!(summary: result.fetch("summary"))
  end

  def save_metadata(result)
    @email.update!(metadata: result.except("summary"))
  end

  def analysis_content
    reader = EmlReader.new(@email)

    [
      email_metadata,
      "CONTENU DE L'EMAIL\n#{reader.body}",
      attachments_content(reader.attachments)
    ].join("\n\n")
  end

  def email_metadata
    [
      "MÉTADONNÉES DE L'EMAIL",
      "Objet : #{@email.subject.presence || 'Sans objet'}",
      "Date d'envoi : #{@email.sent_at || 'Non renseignée'}",
      "Entreprise : #{company_name}",
      "Contact : #{contact_name}",
      "Collaborateur : #{employee_name}"
    ].join("\n")
  end

  def company_name
    @email.contact.company&.name || "Non renseignée"
  end

  def contact_name
    contact = @email.contact
    contact.try(:full_name).presence || contact.try(:name).presence ||
      "Contact ##{@email.contact_id}"
  end

  def employee_name
    @email.employee&.full_name || "Non renseigné"
  end

  def attachments_content(attachments)
    return "PIÈCES JOINTES\nAucune pièce jointe." if attachments.empty?

    attachments.map do |attachment|
      attachment_content(attachment)
    end.join("\n\n")
  end

  def attachment_content(attachment)
    extracted_text = DocumentExtractor.new(attachment).extract_text

    [
      "MÉTADONNÉES DE LA PIÈCE JOINTE",
      "Nom : #{attachment[:filename]}",
      "Type MIME : #{attachment[:content_type] || 'Non renseigné'}",
      "Taille : #{attachment[:content].to_s.bytesize} octets",
      "CONTENU EXTRAIT",
      extracted_text
    ].join("\n")
  end

  def company_prompt
    @email.contact.company&.prompt&.content
  end
end
