class DocumentExtractor
  def initialize(attachment)
    @attachment = attachment
  end

  def extract_text
    filename = @attachment[:filename].to_s.downcase

    case File.extname(filename)
    when ".pdf"
      extract_pdf
    when ".docx"
      extract_docx
    when ".xlsx"
      extract_xlsx
    else
      "Format non pris en charge : #{filename}"
    end
  end

  private

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
