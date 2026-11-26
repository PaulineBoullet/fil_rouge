class DocumentExtractor
  def initialize(attachment)
    @attachment = attachment
  end

  def extract_text
    extension = File.extname(@attachment[:filename].to_s).downcase
    extract_by_extension(extension)
  rescue StandardError => e
    "Pièce jointe illisible : #{e.message}"
  end

  private

  def extract_by_extension(extension)
    return extract_pdf.presence || analyze_visual if extension == ".pdf"
    return analyze_visual if %w[.jpg .jpeg .png].include?(extension)
    return extract_docx if extension == ".docx"
    return extract_xlsx if extension == ".xlsx"

    "Format non pris en charge : #{extension}"
  end

  def analyze_visual
    response = OpenaiService.new.analyze_visual_attachment(@attachment)
    response.output_text
  end

  def extract_pdf
    reader = PDF::Reader.new(StringIO.new(@attachment[:content]))
    reader.pages.map(&:text).join("\n")
  end

  def extract_docx
    doc = Docx::Document.open(StringIO.new(@attachment[:content]))
    doc.paragraphs.map(&:text).join("\n")
  end

  def extract_xlsx
    spreadsheet = Roo::Spreadsheet.open(
      StringIO.new(@attachment[:content]),
      extension: :xlsx
    )

    spreadsheet.sheets.map do |sheet_name|
      sheet = spreadsheet.sheet(sheet_name)
      sheet.to_a.map { |row| row.compact.join(" | ") }.join("\n")
    end.join("\n\n")
  end
end
