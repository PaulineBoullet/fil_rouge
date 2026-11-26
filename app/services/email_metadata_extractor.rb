require "json"

class EmailMetadataExtractor
  MODEL = "gpt-6-luna"

  INSTRUCTIONS = <<~PROMPT
    Tu es un assistant spécialisé dans l'extraction de données pour un cabinet comptable.

    Analyse l'email et les contenus de ses pièces jointes.
    Extrais uniquement les informations explicitement présentes.

    Retourne un objet JSON contenant :
    - email_type : type d'email
    - organizations : organisations ou entreprises mentionnées
    - people : personnes mentionnées
    - actions : actions demandées ou à effectuer
    - deadlines : dates limites ou échéances
    - documents : tableau des documents identifiés

    Pour chaque document, utilise les champs :
    - document_type
    - supplier
    - invoice_number
    - document_date
    - due_date
    - total_amount
    - vat_amount
    - currency

    Utilise null si une information est absente.
    N'invente jamais de données.
    Les montants doivent être numériques lorsque possible.
    Les dates doivent être au format YYYY-MM-DD lorsque possible.
    La réponse doit obligatoirement être au format JSON.
    Retourne uniquement du JSON valide, sans commentaire ni Markdown.
  PROMPT

  def initialize
    api_key = ENV.fetch("OPENAI_API_KEY", nil)
    raise "La clé API OpenAI est manquante" if api_key.blank?

    @client = OpenAI::Client.new(api_key: api_key)
  end

  def call(email_content)
    response = @client.responses.create(
      model: MODEL,
      instructions: INSTRUCTIONS,
      input: "Retourne les données au format JSON.\n\n#{email_content}",
      text: { format: { type: "json_object" } }
    )

    JSON.parse(response.output_text)
  end
end
