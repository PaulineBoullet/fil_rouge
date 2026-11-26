module EmailAnalysisSchema
  INSTRUCTIONS = <<~PROMPT
    Tu es un assistant spécialisé dans l'analyse des emails pour un cabinet comptable.

    Produis un résumé clair en français.
    Extrais également les métadonnées de l'email et de ses pièces jointes.

    Extrais uniquement les informations explicitement présentes.
    N'invente jamais de données.
    Utilise null lorsqu'une information est absente.
    Les montants doivent être numériques lorsque possible.
    Les dates doivent être au format YYYY-MM-DD lorsque possible.

    Retourne uniquement le JSON correspondant au schéma demandé.
  PROMPT

  SCHEMA = {
    type: "object",
    properties: {
      summary: { type: "string" },
      email_type: { type: ["string", "null"] },
      organizations: { type: "array", items: { type: "string" } },
      people: { type: "array", items: { type: "string" } },
      actions: { type: "array", items: { type: "string" } },
      deadlines: { type: "array", items: { type: "string" } },
      documents: {
        type: "array",
        items: {
          type: "object",
          properties: {
            document_type: { type: ["string", "null"] },
            supplier: { type: ["string", "null"] },
            invoice_number: { type: ["string", "null"] },
            document_date: { type: ["string", "null"] },
            due_date: { type: ["string", "null"] },
            total_amount: { type: ["number", "null"] },
            vat_amount: { type: ["number", "null"] },
            currency: { type: ["string", "null"] }
          },
          required: %w[
            document_type supplier invoice_number document_date
            due_date total_amount vat_amount currency
          ],
          additionalProperties: false
        }
      }
    },
    required: %w[
      summary email_type organizations people actions deadlines documents
    ],
    additionalProperties: false
  }.freeze
end
