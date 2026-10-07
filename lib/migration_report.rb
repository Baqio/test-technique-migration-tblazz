class MigrationReport
  Issue = Struct.new(:level, :source, :locator, :message, :details, keyword_init: true)

  attr_reader :issues, :counters

  def initialize
    @issues   = []
    @counters = Hash.new(0)
  end

  def count(key, by = 1)
    @counters[key.to_sym] += by
  end

  def warn(source:, locator:, message:, **details)
    add(:warning, source, locator, message, details)
  end

  def error(source:, locator:, message:, **details)
    add(:error, source, locator, message, details)
  end

  def errors   = issues.select { |issue| issue.level == :error }
  def warnings = issues.select { |issue| issue.level == :warning }

  def to_s
    lines = []
    lines << "Lignes lues : #{counters[:read]}"
    lines << "Importées   : #{counters[:imported]}"
    lines << "Rejetées    : #{errors.size}"
    lines << "À vérifier  : #{warnings.size}"

    errors.group_by(&:message).each do |message, group|
      lines << "> rejet : #{group.size} × #{message} #{line_numbers(group)}"
    end

    warnings.group_by(&:message).each do |message, group|
      lines << "> à vérifier : #{group.size} × #{message} #{line_numbers(group)}"
    end

    lines.join("\n")
  end

  private

  def line_numbers(group)
    numbers = group.map(&:locator).join(", ")
    "(lignes #{numbers})"
  end

  def add(level, source, locator, message, details)
    @issues << Issue.new(level: level, source: source, locator: locator,
                         message: message, details: details)
  end
end
