module EmailAnalysisSchema

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
    # Schéma complet : points saillants + liste fermée des catégories et statuts des Paramètres
  def self.schema
    categories = Category.ordered.pluck(:name)
    statuses = Status.ordered.pluck(:name)

    SCHEMA.deep_merge(
      properties: {
        key_points: { type: "array", items: { type: "string" } },
        category: categories.any? ? { type: "string", enum: categories } : { type: "null" },
        status: statuses.any? ? { type: "string", enum: statuses } : { type: "null" }
      },
      required: SCHEMA[:required] + %w[key_points category status]
    )
  end
end
