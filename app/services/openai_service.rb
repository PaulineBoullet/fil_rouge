require "base64"

class OpenaiService
  MODEL = "gpt-6-luna"

  DEFAULT_INSTRUCTIONS = <<~PROMPT
    Tu es un assistant spécialisé dans l'analyse des emails pour un cabinet comptable.

    Fournis une synthèse claire en français avec :
    - Le sujet principal de l'email
    - Les informations importantes
    - Les pièces jointes mentionnées
    - Les actions à effectuer
    - Les éventuelles échéances
  PROMPT

  def initialize
    api_key = ENV.fetch("OPENAI_API_KEY", nil)
    raise "La clé API OpenAI est manquante" if api_key.blank?

    @client = OpenAI::Client.new(api_key: api_key)
  end

  def test_connection
    @client.responses.create(
      model: MODEL,
      input: "Réponds simplement : Bonjour, la connexion fonctionne !"
    )
  end

  def analyze_email(email_content, instructions: nil)
    combined_instructions = [
      DEFAULT_INSTRUCTIONS,
      instructions
    ].compact_blank.join("\n\n")

    @client.responses.create(
      model: MODEL,
      instructions: combined_instructions,
      input: email_content
    )
  end

  def analyze_visual_attachment(attachment)
    @client.responses.create(
      model: MODEL,
      input: [{ role: "user", content: visual_content(attachment) }]
    )
  end

  private

  def visual_content(attachment)
    extension = File.extname(attachment[:filename].to_s).downcase
    base64 = Base64.strict_encode64(attachment[:content])

    case extension
    when ".jpg", ".jpeg", ".png"
      image_content(extension, base64)
    when ".pdf"
      pdf_content(attachment[:filename], base64)
    else
      raise "Format visuel non pris en charge : #{extension}"
    end
  end

  def image_content(extension, base64)
    mime_type = extension == ".png" ? "image/png" : "image/jpeg"

    [
      { type: "input_text", text: "Lis cette image et retranscris toutes les informations utiles." },
      {
        type: "input_image",
        image_url: "data:#{mime_type};base64,#{base64}",
        detail: "high"
      }
    ]
  end

  def pdf_content(filename, base64)
    [
      { type: "input_text", text: "Lis ce document et retranscris toutes les informations utiles." },
      {
        type: "input_file",
        filename: filename,
        file_data: "data:application/pdf;base64,#{base64}"
      }
    ]
  end
end
