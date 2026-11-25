
class EmlReader
  def initialize(email)
    @email = email
    @mail = Mail.read_from_string(email.content)
  end

  def body
    part = @mail.text_part || @mail.html_part || @mail

    part.decoded.to_s.force_encoding("UTF-8").scrub.strip
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
