class OpenaiService
  def initialize
    api_key = ENV["OPENAI_API_KEY"]

    raise "La clé API OpenAI est manquante" if api_key.blank?

    @client = OpenAI::Client.new(api_key: api_key)
  end

  def test_connection
    response = @client.responses.create(
      model: "gpt-4.1-mini",
      input: "Réponds simplement : Bonjour, la connexion fonctionne !"
    )

    response
  end

  def analyze_email(email_content)
    response = @client.responses.create(
      model: "gpt-4.1-mini",
      input: <<~PROMPT
        Tu es un assistant spécialisé dans l'analyse des emails pour un cabinet comptable.

        Analyse le contenu suivant :
        #{email_content}

        Fournis une synthèse claire en français avec :
        - Le sujet principal de l'email
        - Les informations importantes
        - Les pièces jointes mentionnées
        - Les actions à effectuer
        - Les éventuelles échéances
      PROMPT
    )

    response
  end
end
