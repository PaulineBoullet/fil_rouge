class EmailAnalysisService
  def initialize(email)
    @email = email
  end

  def call
    reader = EmlReader.new(@email)

    email_content = reader.body

    reader.attachments.each do |attachment|
      extracted_text = DocumentExtractor.new(attachment).extract_text
      email_content += "\n\nPièce jointe : #{attachment[:filename]}\n#{extracted_text}"
    end

    response = OpenaiService.new.analyze_email(email_content)

    @email.update!(summary: response.output_text)

    @email.summary
  end
end
