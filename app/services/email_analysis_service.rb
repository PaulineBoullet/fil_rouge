class EmailAnalysisService
  # classify: false quand on analyse tout un fil, pour ne reclasser le fil qu'une fois à la fin
  def initialize(email, classify: true)
    @email = email
    @classify = classify
  end

  def call
    result = OpenaiService.new.analyze_email(
      analysis_content,
      instructions: PromptBuilder.new(company).email_instructions
    )

    save_summary(result)
    save_metadata(result)
    ConversationClassifier.new(@email.conversation).call if @classify && @email.conversation

    @email.summary
  end

  private

  def save_summary(result)
    @email.update!(summary: result.fetch("summary"))
  end

  def save_metadata(result)
    @email.update!(metadata: result.except("summary"))
  end

  # Limite du texte envoyé à l'IA : au-delà, le modèle refuse la requête (pièces jointes volumineuses)
  MAX_INPUT_CHARS = 60_000

  def analysis_content
    reader = EmlReader.new(@email)

    content = [
      email_metadata,
      "CONTENU DE L'EMAIL\n#{reader.body}",
      attachments_content(reader.attachments)
    ].join("\n\n")

    return content if content.length <= MAX_INPUT_CHARS

    "#{content.first(MAX_INPUT_CHARS)}\n\n[Texte tronqué : seuls les #{MAX_INPUT_CHARS} premiers caractères ont été transmis.]"
  end

  def email_metadata
    [
      "MÉTADONNÉES DE L'EMAIL",
      "Objet : #{@email.subject.presence || 'Sans objet'}",
      "Date d'envoi : #{@email.sent_at || 'Non renseignée'}",
      "Domaine tiers : #{company_name}",
      "Expéditeur : #{sender_name}",
      "Destinataires : #{recipient_names}"
    ].join("\n")
  end

  def company
    @email.conversation&.company
  end

  def company_name
    company&.name || "Non renseigné"
  end

  def sender_name
    @email.sender&.display_name || "Non renseigné"
  end

  def recipient_names
    @email.recipients.map(&:display_name).join(", ").presence || "Non renseignés"
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

end
