module ExplorerHelper
  def all_databases
    @all_databases ||= MongoMapper.connection.database_names.sort.select { |d| can_read?(d) }
  end
end