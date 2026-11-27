namespace :fil_rouge do
  desc "Fait analyser par l'IA tous les fils qui l'attendent (synthèses, classement, points clés)"
  task analyser: :environment do
    conversations = ConversationAnalysis.pending.order(:last_email_at).to_a
    puts "#{conversations.size} fil(s) à analyser."
    conversations.each_with_index do |conversation, index|
      print "  #{index + 1}/#{conversations.size} #{conversation.display_title}… "
      ConversationAnalysis.new(conversation).call
      puts "ok"
    rescue StandardError => e
      puts "échec (#{e.message})"
    end
  end
end
