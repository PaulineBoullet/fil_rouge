require "base64"
require "json"

class OpenaiService
  MODEL = "gpt-6-luna"

  DEFAULT_INSTRUCTIONS = <<~PROMPT
    Tu es un assistant spécialisé dans l'analyse des emails pour un cabinet comptable.

    Produis un résumé clair en français.
    Extrais également les métadonnées de l'email et de ses pièces jointes.

    Extrais uniquement les informations explicitement présentes.
    N'invente jamais de données.
    Utilise null lorsqu'une information est absente.
    Les montants doivent être numériques lorsque possible.
    Les dates doivent être au format YYYY-MM-DD lorsque possible.
    Respecte strictement le format JSON demandé.
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

  def analyze_email(content, instructions: nil)
    response = @client.responses.create(
      model: MODEL,
      instructions: analysis_instructions(instructions),
      input: "Analyse cet email et retourne le JSON demandé.\n\n#{content}",
      text: { format: analysis_format }
    )

    JSON.parse(response.output_text)
  end

  def analyze_visual_attachment(attachment)
    @client.responses.create(
      model: MODEL,
      input: [{ role: "user", content: visual_content(attachment) }]
    )
  end

  private

  def analysis_instructions(instructions)
    [DEFAULT_INSTRUCTIONS, instructions].compact_blank.join("\n\n")
  end

  def analysis_format
    {
      type: "json_schema",
      name: "email_analysis",
      strict: true,
      schema: EmailAnalysisSchema::SCHEMA
    }
  end

  def visual_content(attachment)
    extension = File.extname(attachment[:filename]).downcase
    base64 = Base64.strict_encode64(attachment[:content])

    attachment_content(extension, attachment, base64)
  end

  def attachment_content(extension, attachment, base64)
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
    mime = extension == ".png" ? "image/png" : "image/jpeg"

    [
      { type: "input_text", text: "Lis cette image et retranscris les informations utiles." },
      {
        type: "input_image",
        image_url: "data:#{mime};base64,#{base64}",
        detail: "high"
      }
    ]
  end

  def pdf_content(filename, base64)
    [
      { type: "input_text", text: "Lis ce document et retranscris les informations utiles." },
      {
        type: "input_file",
        filename: filename,
        file_data: "data:application/pdf;base64,#{base64}"
      }
    ]
  end
end
