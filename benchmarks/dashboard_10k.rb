# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark'
require 'fileutils'
require 'logger'
require 'sequel'
require 'i18n'
require 'rack/test'

ENV['RACK_ENV'] = 'test'
ENV['SMTP_USER'] ||= 'out@test.com'

BASE_DIR = File.expand_path('..', __dir__)
DB_PATH = ENV.fetch('BENCHMARK_DB', File.join(BASE_DIR, 'tmp', 'dashboard_10k.sqlite'))
ENV['DATABASE_URL'] = "sqlite://#{DB_PATH}"
RECORDS_N = ENV.fetch('RECORDS', '10000').to_i
USERS = [1, 2].freeze
STAGES = %w[screening_title_abstract review_full_text].freeze
WARMUP_RUNS = ENV.fetch('WARMUP', '3').to_i
RUNS = ENV.fetch('RUNS', '10').to_i
SEED = ENV.fetch('SEED', '1234').to_i
BATCH_SIZE = ENV.fetch('BATCH_SIZE', '1000').to_i

FileUtils.mkdir_p(File.join(BASE_DIR, 'tmp'))
FileUtils.mkdir_p(File.join(BASE_DIR, 'log'))
FileUtils.rm_f(DB_PATH) if ENV.fetch('RESET_DB', '1') == '1'

locales_root = File.join(BASE_DIR, 'config', 'locales', '*.yml')
I18n.load_path += Dir[locales_root]
I18n.locale = :en
I18n.config.available_locales = %i[es en]

require_relative '../lib/buhos/create_schema'
require_relative '../lib/buhos/dbadapter'

db = Sequel.connect("sqlite://#{DB_PATH}", encoding: 'utf8', reconnect: false)
if db.tables.empty?
  Buhos::SchemaCreation.create_db_from_scratch(db)
else
  Sequel.extension :migration
  Sequel::Migrator.run(db, File.join(BASE_DIR, 'db', 'migrations'))
end

$db_adapter = Buhos::DBAdapter.new
$db_adapter.logger = Logger.new(File.join(BASE_DIR, 'log', 'benchmark_dashboard_sql.log'))
$db_adapter.use_db(db)
Sequel::Model.db = $db_adapter

require_relative '../app'

Buhos.connect_to_db($db_adapter)

def import_rows(dataset, rows)
  rows.each_slice(BATCH_SIZE) { |slice| dataset.multi_insert(slice) }
end

def ensure_benchmark_review
  sr = SystematicReview[name: 'Benchmark Dashboard 10k']
  return sr if sr

  sr_id = SystematicReview.insert(
    name: 'Benchmark Dashboard 10k',
    group_id: 1,
    sr_administrator: 1,
    date_creation: Date.today,
    objectives: 'Benchmark review',
    description: 'Synthetic review for dashboard benchmark',
    year_start: 2000,
    year_end: 2026,
    stage: 'review_full_text',
    active: true,
    n_min_rr_rtr: 1
  )
  SystematicReview[sr_id]
end

def populate_review(sr)
  return if Record.where(canonical_document_id: 1..RECORDS_N).count >= RECORDS_N

  srand(SEED)
  search_id = Search.insert(
    systematic_review_id: sr.id,
    bibliographic_database_id: 1,
    date_creation: Date.today,
    search_criteria: 'synthetic benchmark search',
    description: 'synthetic benchmark search',
    user_id: 1,
    valid: true,
    source: 'benchmark',
    search_type: 'manual'
  )

  import_rows(CanonicalDocument, (1..RECORDS_N).map do |id|
    {
      id: id,
      type: 'article',
      title: "Benchmark document #{id}",
      author: "Author #{id % 100}",
      journal: "Journal #{id % 20}",
      year: 2000 + (id % 25),
      abstract: "Synthetic abstract #{id}"
    }
  end)

  import_rows(Record, (1..RECORDS_N).map do |id|
    {
      id: id,
      bibliographic_database_id: 1,
      uid: "benchmark:#{id}",
      type: 'article',
      title: "Benchmark record #{id}",
      author: "Author #{id % 100}",
      year: 2000 + (id % 25),
      canonical_document_id: id
    }
  end)

  import_rows(RecordsSearch, (1..RECORDS_N).map { |id| { search_id: search_id, record_id: id } })

  allocation_rows = []
  decision_rows = []
  resolution_rows = []
  decision_values = Decision::N_EST.keys
  resolution_values = [Resolution::RESOLUTION_ACCEPT, Resolution::RESOLUTION_REJECT, nil]

  STAGES.each do |stage|
    (1..RECORDS_N).each do |cd_id|
      USERS.each do |user_id|
        allocation_rows << {
          systematic_review_id: sr.id,
          canonical_document_id: cd_id,
          user_id: user_id,
          stage: stage,
          status: 'benchmark'
        }
        decision_rows << {
          systematic_review_id: sr.id,
          canonical_document_id: cd_id,
          user_id: user_id,
          stage: stage,
          decision: decision_values.sample,
          commentary: 'benchmark'
        }
      end

      resolution = stage == 'screening_title_abstract' ? Resolution::RESOLUTION_ACCEPT : resolution_values.sample
      next if resolution.nil?

      resolution_rows << {
        systematic_review_id: sr.id,
        canonical_document_id: cd_id,
        user_id: 1,
        stage: stage,
        resolution: resolution,
        commentary: 'benchmark'
      }
    end
  end

  import_rows(AllocationCd, allocation_rows)
  import_rows(Decision, decision_rows)
  import_rows(Resolution, resolution_rows)
  Buhos::SchemaCreation.delete_views($db)
end

def percentile(values, percentile)
  sorted = values.sort
  sorted[((sorted.length - 1) * percentile).ceil]
end

sr = ensure_benchmark_review
populate_review(sr)

session = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
session.post('/login', user: 'admin', password: 'admin')
raise "Login failed: #{session.last_response.status}" unless session.last_response.redirect? || session.last_response.ok?

puts "Dashboard benchmark"
puts "records=#{RECORDS_N} users=#{USERS.length} stages=#{STAGES.join(',')} seed=#{SEED}"
puts "db=#{DB_PATH}"

WARMUP_RUNS.times do
  session.get("/review/#{sr.id}/dashboard")
  raise "Warmup failed: #{session.last_response.status}" unless session.last_response.ok?
end

times = RUNS.times.map do
  Benchmark.realtime do
    session.get("/review/#{sr.id}/dashboard")
    raise "Request failed: #{session.last_response.status}" unless session.last_response.ok?
  end
end

avg = times.sum / times.length
puts format('runs=%<runs>d avg=%<avg>.4fs min=%<min>.4fs median=%<median>.4fs p95=%<p95>.4fs max=%<max>.4fs',
            runs: times.length,
            avg: avg,
            min: times.min,
            median: percentile(times, 0.50),
            p95: percentile(times, 0.95),
            max: times.max)
