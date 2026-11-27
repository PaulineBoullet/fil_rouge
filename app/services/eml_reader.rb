# Lecture d'un mail enregistré : texte et pièces jointes, à l'aide de la gem mail
class EmlReader
  # Texte lisible d'un mail : la partie texte, sinon la partie HTML sans ses balises
  def self.body_text(mail)
    part = mail.text_part || mail.html_part || mail
    text = part.decoded.to_s.dup.force_encoding("UTF-8").scrub
    text = Nokogiri::HTML(text).text if part.mime_type == "text/html"
    text.strip
  end

  def initialize(email)
    @email = email
    @mail = Mail.read_from_string(email.content)
  end

  def body
    self.class.body_text(@mail)
  end

  def attachments
    @mail.attachments.map do |attachment|
      {
        filename: attachment.filename,
        content_type: attachment.mime_type,
        content: attachment.decoded
      }
    end
  end
end
