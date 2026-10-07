module Importer::Normalization
  module_function

  COUNTRY_CODES = {
    "FRANCE" => "FR", "FR" => "FR",
    "BELGIQUE" => "BE", "BE" => "BE",
    "ALLEMAGNE" => "DE", "DE" => "DE"
  }.freeze

  PHONE_NOT_PROVIDED = "N/C".freeze
  FRENCH_PHONE_PREFIX = "+33".freeze
  DATE_FORMAT = "%d/%m/%Y".freeze

  def text(value)
    sanitized = value.to_s.strip
    return nil if sanitized.empty?
    sanitized
  end

  def upcase_text(value)
    upcasetext = text(value)
    return nil if upcasetext.nil?
    upcasetext.upcase
  end

  def zip(value, _country_code = "FR")
    zip = text(value)
    if !zip.nil? && _country_code == "FR" && zip.length == 4
      "0"+zip
    else
      zip
    end
  end

  def phone(value)
    phone = text(value)
    return nil if phone.nil? || phone == PHONE_NOT_PROVIDED
    phone = phone.delete(" .")
    if phone.start_with?(FRENCH_PHONE_PREFIX)
      phone = phone.sub(FRENCH_PHONE_PREFIX, "0")
    end
    if phone.length == 9
      phone = "0" + phone
    end
    phone
  end

  def email(value)
    email = text(value)
    return nil if email.nil?
    email = email.downcase
    return nil unless email.match?(URI::MailTo::EMAIL_REGEXP)
    email
  end

  def country_code(value)
    country = text(value)
    return nil if country.nil?
    COUNTRY_CODES[country.upcase]
  end

  def date(value)
    return value if value.is_a?(Date)
    date = text(value)
    return nil if date.nil?
    Date.strptime(date, DATE_FORMAT)
  rescue ArgumentError
    nil
  end

  def vat_number(value)
    vat_number = text(value)
    return nil if vat_number.nil?
    vat_number.delete(" ").upcase
  end

  def decimal(value)
    value.to_s.to_f
  end
end
