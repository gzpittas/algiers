class PdfImportsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Renders the upload form
  end

  def create
    uploaded_file = params[:pdf_file]
    unless uploaded_file&.respond_to?(:read)
      return redirect_to new_pdf_import_path, alert: "Please upload a valid PDF file."
    end

    # 1. Create a uniquely named temp file using a UUID to prevent race conditions
    unique_filename = "#{SecureRandom.uuid}-#{uploaded_file.original_filename}"
    temp_path = Rails.root.join("tmp", unique_filename)

    emails_count = 0

    begin
      # 2. Write the uploaded file content to the secure temporary location
      File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }

      # 3. Process the file using the parser service
      parser = PdfParser.new(temp_path)
      emails = parser.extract_emails
      emails_count = emails.count

      # 4. Create database records
      issue = ProductionIssue.create!(
        issue_number: parser.issue_number,
        file_name: uploaded_file.original_filename
      )

      # Use the extracted production name from the parser
      production = issue.productions.create!(name: parser.production_name)

      # === START FIX: Global uniqueness check for Email records ===
      emails.each do |email_address|
        # Check if the email address already exists anywhere in the database (global lookup).
        email_record = Email.find_by(address: email_address)

        unless email_record
          # If it is a brand new, unique email address, create the record and link it to the current production.
          Email.create!(address: email_address, production: production)
        end
        # If the email_record exists, we simply skip creation, preventing the duplicate database row.
        # NOTE: Due to your current schema (Email belongs_to Production),
        # an existing email will remain linked to its original production.
      end
      # === END FIX ===

      redirect_to pdf_imports_path, notice: "#{emails_count} email(s) extracted from #{uploaded_file.original_filename} (Issue: #{issue.issue_number})."

    rescue => e
      # Handle any exceptions during file processing or database operations
      Rails.logger.error "PDF Import Failed: #{e.message}\n#{e.backtrace.join("\n")}"
      redirect_to new_pdf_import_path, alert: "An error occurred during processing. Please check the file format."

    ensure
      # 5. CRITICAL: Ensure the temporary file is deleted, regardless of success or failure
      File.delete(temp_path) if File.exist?(temp_path)
    end
  end

  def index
    @issues = ProductionIssue.includes(productions: :emails).order(created_at: :desc)
  end
end
