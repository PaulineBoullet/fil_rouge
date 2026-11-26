# Importe un mail au format .eml :
# 1. ignore un mail déjà présent (même Message-ID, exporté par plusieurs boîtes) ;
# 2. enregistre le mail complet (en-têtes, texte, pièces jointes) ;
# 3. crée une ligne par adresse, reliée à son collaborateur ou à son correspondant ;
# 4. rattache le mail à son fil.
# Tout se fait dans une transaction : un mail est intégré entièrement ou pas du tout.
class EmailImporter
  Result = Struct.new(:status, :email, :error, keyword_init: true)

  # Importe une liste de fichiers ; les échecs sont enregistrés dans import_failures
  def self.import_files(paths, org_domain: Setting.org_domain)
    resolver = AddressResolver.new(org_domain: org_domain)
    paths.map do |path|
      result = new(File.binread(path), resolver: resolver).call
      ImportFailure.record(File.basename(path), result.error) if result.status == :failed
      ImportFailure.where(filename: File.basename(path)).delete_all if result.status == :imported
      result
    rescue SystemCallError => e
      ImportFailure.record(File.basename(path), "Fichier illisible : #{e.message}")
      Result.new(status: :failed, error: e.message)
    end
  end

  def initialize(raw, resolver: AddressResolver.new)
    @raw = raw.to_s.dup.force_encoding("UTF-8").scrub
    @resolver = resolver
  end

  def call
    mail = Mail.new(@raw)
    raise ArgumentError, "aucun en-tête de mail reconnu" if mail.header.fields.empty?

    message_id = normalize_id(mail.message_id).presence || fallback_message_id
    existing = Email.find_by(message_id: message_id)
    return Result.new(status: :duplicate, email: existing) if existing

    email = nil
    ActiveRecord::Base.transaction do
      email = Email.create!(
        message_id: message_id,
        subject: mail.subject,
        content: @raw,
        sent_at: mail.date,
        in_reply_to: ids_from(mail.in_reply_to).last,
        reference_ids: ids_from(mail.references),
        attachments_count: mail.attachments.size
      )
      create_participants(email, mail)
      email.email_participants.reload
      ConversationResolver.new(email).call
    end
    Result.new(status: :imported, email: email)
  rescue StandardError => e
    Result.new(status: :failed, error: "#{e.class} : #{e.message}")
  end

  private

  def create_participants(email, mail)
    { from: :from, to: :to, cc: :cc }.each do |role, header|
      addresses_of(mail[header]).each do |address, name|
        person = @resolver.call(address, name)
        email.email_participants.create!(role: role, address: address.downcase, name: name.presence, **person)
      end
    end
  end

  # [[adresse, nom affiché], …] ; un en-tête mal formé ne bloque pas l'import
  def addresses_of(field)
    return [] if field.nil?
    return [] unless field.respond_to?(:addrs)

    field.addrs.filter_map { |a| [a.address, a.display_name] if a.address.present? }
  rescue StandardError
    []
  end

  def ids_from(value)
    Array(value).flatten.flat_map { |v| v.to_s.split(/\s+/) }.map { |v| normalize_id(v) }.compact_blank
  end

  def normalize_id(value)
    value.to_s.strip.delete_prefix("<").delete_suffix(">")
  end

  def fallback_message_id
    "sans-id-#{Digest::SHA256.hexdigest(@raw)[0, 32]}@fil-rouge.local"
  end
end
