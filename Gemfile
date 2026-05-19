source "https://gem.coop"

source "https://rubygems.org" do
  gem "fresco"
end

group :development do
  # Lints user code against the Spinel-acceptable Ruby subset.
  # `fresco build` wires this in to fail the build on violations.
  gem "rubocop_spinel"

  # Powers `fresco dev`'s CRuby stand-in for the SQLite / Postgres FFI
  # shims. Production binaries link libsqlite3 / libpq directly via
  # the C shims that ship in the fresco gem — these are dev-only
  # conveniences so actions that hit Fresco::Db::Active work under
  # CRuby without a Spinel recompile.
  gem "sqlite3"
  gem "pg"
end
