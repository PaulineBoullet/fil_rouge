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
end
