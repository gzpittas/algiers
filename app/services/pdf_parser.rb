require 'pdf-reader'

class PdfParser
  # Initializes the parser with the file path.
  # This service is responsible for reading and extracting data.
  def initialize(file_path)
    @file_path = file_path
  end

  # Extract all unique email addresses from the PDF text.
  def extract_emails
    # Find all potential email matches
    potential_emails = text.scan(/@[a-z0-9][a-z0-9.-]*\.[a-z]{2,}/i)
    
    # For each match, work backwards to find the start of the email
    emails = potential_emails.map do |email_end|
      extract_complete_email(email_end)
    end.compact.uniq
    
    # Filter out invalid emails
    emails.select { |email| valid_email_format?(email) }
  end

  # Try to detect the issue number (e.g. "1468").
  # This pattern searches for "Issue " followed by 3 to 5 digits, case-insensitive.
  def issue_number
    match = text.match(/Issue\s+(\d{3,5})/i)
    match ? match[1] : "Unknown"
  end

  # Placeholder for more complex data extraction, like a production name.
  def production_name
    # Implement logic to find a production name based on keywords or location in the PDF.
    # For now, it defaults to a recognizable placeholder.
    "Extracted Production Name"
  end

  private

  # Read and cache the full text of the PDF.
  def text
    @text ||= begin
      # Use the block form for PDF::Reader for robust resource management.
      PDF::Reader.open(@file_path) do |reader|
        reader.pages.map(&:text).join("\n")
      end
    end
  rescue PDF::Reader::MalformedPDFError => e
    Rails.logger.error "PDF Malformed: #{@file_path} - #{e.message}"
    "" # Return empty string if the PDF is unreadable
  end

  # Extract the complete email by finding where it starts
  def extract_complete_email(email_with_at)
    # Find the position of this email fragment in the text
    position = text.index(email_with_at)
    return nil unless position
    
    # Look backwards from the @ symbol to find the start
    # Valid characters for local part: letters, numbers, dots, underscores, percent, plus, hyphen
    local_part = ""
    i = position - 1
    
    while i >= 0
      char = text[i]
      # Stop at whitespace or invalid characters
      break if char.match?(/[\s,;:()\[\]<>{}\/\\|]/)
      # Stop if we hit something that looks like the end of another field
      break if i > 0 && char.match?(/[A-Z]/) && text[i-1].match?(/[a-z]/) && local_part.length > 0
      
      local_part = char + local_part
      i -= 1
    end
    
    # Remove any leading invalid characters
    local_part = local_part.sub(/^[^a-z0-9]+/i, '')
    
    # Check if local part starts with something that looks like a phone number or zip code pattern
    # Remove patterns like: 310-633-2905, 604-873-9739, 90094, etc.
    local_part = local_part.sub(/^.*?(\d{3,5}[-\s]?\d{3,4}[-\s]?\d{4})/, '')
    local_part = local_part.sub(/^[A-Z]{2,}[\d-]+/, '') # State codes + numbers
    local_part = local_part.sub(/^\d{5,}[-\s]?\d*/, '') # Zip codes
    local_part = local_part.sub(/^[A-Z\d]+[-\s]\d+[-\s]?\d*/, '') # Various number patterns
    
    # Remove leading special characters again after cleanup
    local_part = local_part.sub(/^[^a-z0-9]+/i, '')
    
    return nil if local_part.empty?
    
    "#{local_part}#{email_with_at}"
  end

  # Validate email format more strictly
  def valid_email_format?(email)
    # Must have exactly one @
    return false unless email.count('@') == 1
    
    local, domain = email.split('@')
    
    # Local part validations
    return false if local.empty? || local.length > 64
    return false if local.start_with?('.') || local.end_with?('.')
    return false if local.include?('..')
    
    # Reject if local part is all uppercase (likely company name)
    return false if local.match?(/^[A-Z]+$/)
    
    # Reject if local part still contains invalid patterns
    return false if local.match?(/\d{3}[-\s]?\d{3}[-\s]?\d{4}/) # Phone numbers
    return false if local.match?(/^[A-Z]{2}\d/) # State + numbers
    
    # Domain validations
    return false if domain.empty? || domain.length > 255
    return false if domain.start_with?('.') || domain.end_with?('.')
    return false if domain.start_with?('-') || domain.end_with?('-')
    return false unless domain.include?('.')
    
    # Domain must end with valid TLD (at least 2 letters)
    return false unless domain.match?(/\.[a-z]{2,}$/i)
    
    true
  end
end