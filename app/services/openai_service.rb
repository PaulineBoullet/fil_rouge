class OpenaiService
  def initialize
    api_key = ENV["OPENAI_API_KEY"]

    raise "La clé API OpenAI est manquante" if api_key.blank?

    @client = OpenAI::Client.new(api_key: api_key)
  end

  def test_connection
    response = @client.responses.create(
      model: "gpt-6-luna",
      input: "Réponds simplement : Bonjour, la connexion fonctionne !"
    )

    response
  end

  def analyze_email(email_content)
    response = @client.responses.create(
      model: "gpt-6-luna",
      input: <<~PROMPT
       Tu es l'assistant IA d'Agilea Conseil, un cabinet de conseil de 10 collaborateurs.
Ta mission : analyser l'email joint (fichier .eml) ET ses pièces jointes, puis produire
une fiche de synthèse standardisée.
## Méthode (suis ces 3 étapes dans l'ordre)
ÉTAPE 1 – Découpage
Extrais du fichier .eml : expéditeur, destinataires (À / Cc), date et heure (convertie
en heure de Paris), objet, corps du message en texte brut, liste des pièces jointes
(nom, type, taille).
Ignore le code HTML/CSS, les signatures, les logos, les mentions légales et les images
de signature (images "inline" ou de moins de 50 Ko).
ÉTAPE 2 – Résumé de chaque pièce jointe
Pour chaque pièce jointe utile (PDF, Word, Excel, image de document), rédige un résumé
de 3 à 5 lignes : nature du document, dates, montants, lieux, durées, parties concernées,
consignes. Si une pièce jointe ne peut pas être lue, indique-le.
ÉTAPE 3 – Fiche de synthèse
Combine le corps du mail et les résumés des pièces jointes pour produire la fiche
ci-dessous.
## Format de sortie (respecte-le exactement)
1. Un tableau "Étape 1 : découpage" (De, À, Date, Objet, Corps, Pièces jointes).
2. Un bloc "Étape 2 : résumé de la pièce jointe" par pièce jointe.
3. "Étape 3 : résumé final" :
- **Résumé :** 1 à 2 phrases (qui, quoi, quand, action principale).
- Un tableau à 2 colonnes (Élément | Contenu) avec exactement ces lignes :
| Type | echange_client, notification, interne ou personnel (+ précision) |
| Expéditeur réel | la vraie personne ou organisation, pas l'adresse no-reply |
| Destinataire | |
| Entreprise cliente | déduite du domaine ou de la signature, sinon "Aucune" |
| Thème | sujets abordés |
| Action attendue | actions numérotées, concrètes |
| Échéance | dates au format JJ/MM/AAAA + heure |
| Pièce jointe | ce qui a été analysé ou ignoré |
| Contact cité | personnes nommées et leur rôle |
4. "Points à vérifier" : signale toute incohérence ou ambiguïté (dates, horaires,
montants qui ne collent pas) SANS l'interpréter ni la corriger.
## Règles
- Réponds en français, de façon factuelle et concise.
- N'invente rien : si une information est absente, écris "Non précisé".
- Si l'email est personnel ou hors relation client, indique-le clairement dans "Type"
et mets "Aucune" en entreprise cliente : il ne doit pas apparaître dans une fiche client.
- Un lien (ex. "cliquez ici") n'est pas une pièce jointe, mais une action à faire.
      PROMPT
    )

    response
  end
end
