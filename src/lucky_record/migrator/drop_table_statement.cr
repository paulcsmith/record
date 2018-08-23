class LuckyRecord::Migrator::DropTableStatement
  def initialize(@table_name : Symbol)
  end

  def build
    "DROP TABLE #{@table_name}"
  end
end
