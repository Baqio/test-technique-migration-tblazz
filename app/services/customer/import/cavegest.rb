class Customer::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  KINDS_BY_FAMILY_CODE = { "C" => "customer", "F" => "supplier", "P" => "prospect" }.freeze
  ACTIVE_BY_UNUSABLE_FLAG = { "0" => true, "1" => false }.freeze

  SHEET_NAME = "Feuil1".freeze
  HEADER_ROW = 1

  COLUMNS = [
    ["Code", :reference],
    ["Nom", :last_name],
    ["Prénom", :first_name],
    ["Libellé", :company_name],
    ["Adresse", :address1],
    ["Code postal", :zip],
    ["Ville", :city],
    ["Pays", :country_code],
    ["EMail", :email],
    ["Téléphone 1", :phone],
    ["Téléphone 2", :mobile],
    ["Nom", :shipping_last_name],
    ["Prénom", :shipping_first_name],
    ["Libellé", :shipping_company_name],
    ["Adresse", :shipping_address1],
    ["Code postal", :shipping_zip],
    ["Ville", :shipping_city],
    ["Pays", :shipping_country_code],
    ["Téléphone 1", :shipping_phone],
    ["Code famille client", :family_code],
    ["Libellé famille client", :family_label],
    ["Code categ tarif", :price_grid_code],
    ["Libellé categ tarif", :price_grid_label],
    ["Numéro de TVA", :vat_number],
    ["Numéro d Accise", :excise_number],
    ["Date de création", :creation_date],
    ["Inutilisable", :unusable]
  ].freeze

  HEADERS = COLUMNS.map(&:first).freeze
  FIELDS  = COLUMNS.map(&:last).freeze

  def call
    ensure_headers!(sheet.row(HEADER_ROW), HEADERS)
    Customer.transaction do
      rows.each do |line, row|
        import_row(line, row)
      end
    end
  end

  private

  def import_row(line, row)
    # There will be column check, but for lisibility better to display clearer message when row is completly empty.
    if blank_row?(row)
      report.warn(source: source, locator: line, message: "ligne vide ignorée")
      return
    end

    report.count(:read)
    attributes = attributes_for(row)
    Customer.transaction(requires_new: true) do
      Customer.create!(attributes)
    end
    report.count(:imported)
    warn_invalid_email(line, row, attributes)
  rescue Importer::InvalidRow, ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
    report.error(source: source, locator: line, message: e.message.strip)
  end

  def attributes_for(row)
    country_code = N.country_code(row[:country_code])
    shipping_country_code = N.country_code(row[:shipping_country_code])
    attributes = {
      reference:             N.text(row[:reference]),
      company_name:          N.text(row[:company_name]),
      first_name:            N.text(row[:first_name]),
      last_name:             N.text(row[:last_name]),
      address1:              N.text(row[:address1]),
      city:                  N.text(row[:city]),
      zip:                   N.zip(row[:zip], country_code),
      country_code:          country_code,
      phone:                 N.phone(row[:phone]),
      mobile:                N.phone(row[:mobile]),
      email:                 N.email(row[:email]),
      kind:                  kind_for(row),
      customer_category:     N.upcase_text(row[:family_label]),
      price_grid_code:       N.text(row[:price_grid_code]),
      vat_number:            N.vat_number(row[:vat_number]),
      excise_number:         N.text(row[:excise_number]),
      creation_date:         N.date(row[:creation_date]),
      active:                active_for(row),
      shipping_company_name: N.text(row[:shipping_company_name]),
      shipping_first_name:   N.text(row[:shipping_first_name]),
      shipping_last_name:    N.text(row[:shipping_last_name]),
      shipping_address1:     N.text(row[:shipping_address1]),
      shipping_city:         N.text(row[:shipping_city]),
      shipping_zip:          N.zip(row[:shipping_zip], shipping_country_code),
      shipping_country_code: shipping_country_code,
      shipping_phone:        N.phone(row[:shipping_phone])
    }
    attributes[:use_billing_address] = same_shipping_address?(attributes)
    attributes
  end


  def blank_row?(row)
    row.values.all?(&:blank?)
  end

  # ========= DATA IMPORT HELPERS ===========

  def kind_for(row)
    family_code = N.text(row[:family_code])
    kind = KINDS_BY_FAMILY_CODE[family_code]
    if kind.nil?
      raise Importer::InvalidRow, "code famille #{family_code} (#{N.text(row[:family_label])}) inconnu"
    end
    kind
  end

  def active_for(row)
    unusable = N.text(row[:unusable])
    active = ACTIVE_BY_UNUSABLE_FLAG[unusable]
    if active.nil?
      raise Importer::InvalidRow, "valeur Inutilisable #{unusable} non reconnue"
    end
    active
  end

  def same_shipping_address?(attributes)
    return true if attributes[:shipping_address1].nil?
    attributes[:shipping_address1] == attributes[:address1] &&
      attributes[:shipping_zip] == attributes[:zip] &&
      attributes[:shipping_city] == attributes[:city] &&
      attributes[:shipping_country_code] == attributes[:country_code]
  end

  # compare if mail has been droped because of invalidity to create warn report.
  def warn_invalid_email(line, row, attributes)
    return if row[:email].blank? || attributes[:email].present?
    report.warn(source: source, locator: line, message: "email invalide, non repris", value: N.text(row[:email]))
  end

  # ===================================

  def rows
    rows_by_line = {}
    (HEADER_ROW + 1).upto(sheet.last_row) do |line|
      rows_by_line[line] = FIELDS.zip(sheet.row(line)).to_h
    end
    rows_by_line
  end

  def sheet
    @sheet ||= Roo::Excelx.new(path).sheet(SHEET_NAME)
  rescue IOError, TypeError, RangeError => e #wrong file, wrong sheet and wrong format 
    raise Importer::InvalidFile, "#{source} : #{e.message}"
  end
end
