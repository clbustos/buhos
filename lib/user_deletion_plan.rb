require 'set'
require 'digest'
require 'securerandom'

# Discover the actual foreign keys, including per-review extraction tables.
# The same row set drives the confirmation screen and the deletion.
class UserDeletionPlan
  class Changed < StandardError; end
  attr_reader :user_ids

  def self.normalize_ids(ids)
    raise ArgumentError unless ids.is_a?(Array) && !ids.empty? && ids.all? { |id| id.to_s.match?(/\A[1-9][0-9]*\z/) }
    ids.map(&:to_i).uniq.sort
  end

  def initialize(ids, db=$db)
    @user_ids=self.class.normalize_ids(ids)
    @db=db
    @metadata={}
    @references=[]
    @analysis_dependencies=[]
    @rows=Hash.new { |hash, key| hash[key]=Set.new }
    @db.tables.each do |table|
      schema=@db.schema(table).to_h
      keys=schema.select { |_, info| info[:primary_key] }.keys
      keys=schema.keys if keys.empty?
      @metadata[table]={schema: schema, keys: keys, columns: keys.dup}
      if table.to_s.match?(/\Aanalysis_sr_[0-9]+\z/)
        @analysis_dependencies << {child: table, parent: :systematic_reviews}
      end
    end
    @metadata.each_key do |table|
      @db.foreign_key_list(table).each do |foreign_key|
        parent=foreign_key[:table].to_sym
        next unless @metadata.key?(parent)
        keys=foreign_key[:key] || @metadata[parent][:keys]
        @metadata[parent][:columns] |= keys
        @references << {child: table, parent: parent, columns: foreign_key[:columns], keys: keys}
      end
    end
    @rows[:users].merge(@db[:users].where(id: @user_ids).select(*@metadata[:users][:columns]).all)
    loop do
      changed=false
      @references.each do |reference|
        parents=@rows[reference[:parent]]
        next if parents.empty?
        values=parents.map { |row| reference[:keys].map { |key| row[key] } }.reject { |tuple| tuple.any?(&:nil?) }
        next if values.empty?
        table=reference[:child]
        children=@db[table].where(condition(reference[:columns], values)).select(*@metadata[table][:columns]).all
        previous=@rows[table].size
        @rows[table].merge(children)
        changed=true if @rows[table].size != previous
      end
      # Extraction tables identify their review in the table name rather than
      # in a foreign-key column. A deleted review loses all extraction rows.
      @rows[:systematic_reviews].each do |review|
        table=:"analysis_sr_#{review[:id]}"
        next unless @metadata.key?(table)
        previous=@rows[table].size
        @rows[table].merge(@db[table].select(*@metadata[table][:columns]).all)
        changed=true if @rows[table].size != previous
      end
      break unless changed
    end
  end

  def related_tables
    @rows.reject { |table, rows| table == :users || rows.empty? }.sort_by { |table, _| table.to_s }.map do |table, rows|
      {table: table, count: rows.size}
    end
  end

  def shared_resources?
    !@rows[:groups].empty? || !@rows[:systematic_reviews].empty?
  end

  def signature
    snapshot=@rows.reject { |_, rows| rows.empty? }.sort_by { |table, _| table.to_s }.map do |table, rows|
      [table, rows.map { |row| row.sort_by { |key, _| key.to_s } }.sort_by(&:inspect)]
    end
    Digest::SHA256.hexdigest(Marshal.dump(snapshot))
  end

  def delete!
    @db.transaction do
      current=self.class.new(@user_ids, @db)
      raise Changed unless current.signature == signature
      current.delete_rows!
    end
  end

  protected

  def delete_rows!
    # Replies refer to other messages in the same table. Clear these references
    # only inside rows being deleted, so MySQL's immediate FK checks also pass.
    @references.select { |reference| reference[:child] == reference[:parent] }.each do |reference|
      table=reference[:child]
      next if @rows[table].empty?
      if reference[:columns].all? { |column| @metadata[table][:schema][column][:allow_null] }
        each_scope(table) { |scope| scope.update(reference[:columns].to_h { |column| [column, nil] }) }
      end
    end
    remaining=@rows.keys.select { |table| !@rows[table].empty? }
    until remaining.empty?
      leaves=remaining.reject do |table|
        (@references + @analysis_dependencies).any? { |reference| reference[:parent] == table && reference[:child] != table && remaining.include?(reference[:child]) }
      end
      raise Sequel::Error, 'Circular foreign keys prevent user deletion' if leaves.empty?
      leaves.each { |table| each_scope(table, &:delete) }
      remaining-=leaves
    end
  end

  private

  def condition(columns, tuples)
    columns.size == 1 ? {columns.first=>tuples.map(&:first).uniq} : {columns=>tuples.uniq}
  end

  def each_scope(table)
    @rows[table].to_a.each_slice(100) do |rows|
      keys=@metadata[table][:keys]
      tuples=rows.map { |row| keys.map { |key| row[key] } }
      # Tables without a primary key may contain NULLs; match their full rows.
      predicate=tuples.any? { |tuple| tuple.any?(&:nil?) } ? Sequel.or(*rows.map { |row| row.slice(*keys) }) : condition(keys, tuples)
      yield @db[table].where(predicate)
    end
  end
end
