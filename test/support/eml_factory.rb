# Fabrique de petits mails .eml pour les tests d'import.
module EmlFactory
  def eml(id:, from:, to:, cc: nil, subject: "Objet", date: "Tue, 24 Nov 2026 10:00:00 +0100", in_reply_to: nil, references: nil, body: "Bonjour")
    headers = ["From: #{from}", "To: #{to}"]
    headers << "Cc: #{cc}" if cc
    headers += ["Subject: #{subject}", "Date: #{date}", "Message-ID: <#{id}>"]
    headers << "In-Reply-To: <#{in_reply_to}>" if in_reply_to
    headers << "References: #{Array(references).map { |r| "<#{r}>" }.join(' ')}" if references
    headers += ["MIME-Version: 1.0", "Content-Type: text/plain; charset=utf-8"]
    "#{headers.join("\r\n")}\r\n\r\n#{body}\r\n"
  end

  def import(raw)
    EmailImporter.new(raw, resolver: AddressResolver.new(org_domain: "kelenn.test")).call
  end
end
