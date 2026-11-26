class EmailAnalysisService
  def initialize(email)
    @email = email
  end

  def call
    content = analysis_content

    save_analysis(
      generate_summary(content),
      generate_metadata(content)
    )

    @email.summary
  end

  private

  def generate_summary(content)
    OpenaiService.new.analyze_email(
      content,
      instructions: company_prompt
    ).output_text
  end

  def generate_metadata(content)
    EmailMetadataExtractor.new.call(content)
  end

  def save_analysis(summary, metadata)
    @email.update!(
      summary: summary,
      metadata: metadata
    )
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
      "Identifiant : #{@email.id}",
      "Message-ID : #{@email.message_id}",
      "Objet : #{email_subject}",
      "Date d'envoi : #{email_date}",
      "Entreprise : #{company_name}",
      "Contact : #{contact_name}",
      "Collaborateur : #{employee_name}"
    ].join("\n")
  end

  def email_subject
    @email.subject.presence || 'Sans objet'
  end

  def email_date
    @email.sent_at || 'Non renseignée'
  end

  def company_name
    @email.contact.company&.name || 'Non renseignée'
  end

  def contact_name
    contact = @email.contact
    contact.try(:full_name).presence || contact.try(:name).presence ||
      "Contact ##{@email.contact_id}"
  end

  def employee_name
    @email.employee&.full_name || 'Non renseigné'
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
