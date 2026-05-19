# bookshelf

A Fresco app — Ruby that compiles to a static binary via Spinel.

## Getting started

```
bundle install
bin/dev
```

Then open <http://localhost:3030/>.

## Layout

- `app/actions/` — request handlers. Add a file, point a route at it.
- `app/views/` — ERB templates compiled at build time.
- `app/models/` — model declarations (drive generated DB helpers).
- `config/routes.rb` — route table.
- `config/database.rb` — adapter + DSN.
- `db/schema.rb` — table definitions.
- `db/migrations/` — versioned SQL migrations.

## Commands

- `bin/dev` — CRuby dev loop with auto-reload. Edit + refresh.
- `bin/build` — regenerate `generated/` without booting the server.
- `bin/release` — compile a production binary to `build/app`.

You'll need the `spinel` binary on PATH (or symlinked into this
directory) for `bin/release`. See the Fresco docs for how to obtain
it.
