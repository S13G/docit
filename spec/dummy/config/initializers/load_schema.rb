# frozen_string_literal: true

# The dummy app has no migration/setup step in CI or the test suite, so load
# the schema on boot whenever the expected tables are missing. This keeps the
# database ready for specs, `rails runner`, and the console without a manual
# `db:schema:load`. Idempotent: it no-ops once the tables exist.
Rails.application.config.after_initialize do
  connection = ActiveRecord::Base.connection
  unless connection.table_exists?(:users)
    load Rails.root.join("db", "schema.rb")
  end
rescue ActiveRecord::NoDatabaseError
  # No database file yet — create it, then load the schema.
  ActiveRecord::Tasks::DatabaseTasks.create_current
  load Rails.root.join("db", "schema.rb")
end
