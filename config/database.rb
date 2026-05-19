# Fresco: database configuration. Loaded twice — once by bin/build
# to capture the adapter symbol (drives the codegen template
# selection in generated/db_adapter.rb), and once at runtime as
# part of boot.rb so ENV.fetch'd values resolve in the running
# binary's environment rather than at build time.
#
# Switching adapters requires re-running bin/build (the linker picks
# one C shim or the other; we don't link both). For SQLite, the path
# can be `:memory:` for an ephemeral in-process DB, or any filesystem
# path. For Postgres, pass any libpq conninfo string —
# `postgres://user@host/db` or `host=... user=... dbname=...`.
#
#   Fresco.database :postgres, url: ENV.fetch("DATABASE_URL", "postgres://localhost/app_dev")

# Fresco.database :sqlite,
#   path: ENV.fetch("DATABASE_PATH", ":memory:")

Fresco.database :postgres,
  url: ENV.fetch("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/fresco_development")
