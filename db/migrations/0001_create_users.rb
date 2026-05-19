# Bring the users table into existence. Mirrors db/schema.rb's
# declaration — for M5 the developer keeps schema.rb and migrations
# in sync by hand (the M6+ schema dumper would automate it). Adapter
# syntax differs (SERIAL vs INTEGER PRIMARY KEY AUTOINCREMENT), so
# pick the form your config/database.rb's adapter expects. The
# block runs at build time under CRuby; pick at evaluation time.
#
# For now we hardcode the SQLite shape — Postgres callers can edit
# this file, or M6+ codegen can branch on `Fresco.database_adapter`
# inside the migration body.

Fresco.migration "0001_create_users" do
  up do
    if Fresco.database_adapter == :postgres
      sql "CREATE TABLE users (id SERIAL PRIMARY KEY, email TEXT NOT NULL UNIQUE, name TEXT, created_at INTEGER)"
    else
      sql "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL UNIQUE, name TEXT, created_at INTEGER)"
    end
  end

  down do
    sql "DROP TABLE users"
  end
end
