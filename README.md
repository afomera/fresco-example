# fresco-example

A tour app for the [Fresco][fresco] framework — small actions and views
that exercise routing, views/layouts/partials, the build-time model DSL,
both DB adapters, file streaming, filters, and flash messaging. Use it as
a reference when building your own app.

[fresco]: https://github.com/afomera/fresco

## Setup

### 1. Install Fresco

The gem is pulled in via this app's `Gemfile`:

```sh
bundle install
```

### 2. Build Spinel

`bin/dev` runs under CRuby and doesn't need Spinel. `bin/release` does
— Spinel is what AOT-compiles the app into `build/app`.

```sh
git clone https://github.com/matz/spinel.git
cd spinel
make deps
make all
```

That produces a `spinel` binary in the repo root.

### 3. Link the Spinel binary into this app

`fresco release` looks for `./spinel`, then `./vendor/spinel/bin/spinel`,
then `spinel` on `$PATH`. The simplest setup is a symlink at the app
root (this repo already gitignores it):

```sh
cd /path/to/fresco-example
ln -s /absolute/path/to/spinel/spinel ./spinel
```

> On macOS, `bin/release` auto-detects Homebrew's keg-only `libpq` and
> Postgres.app so the libpq shim compiles without manual env exports.

### 4. (Optional) Set up Postgres

`config/database.rb` defaults to:

```
postgres://postgres:postgres@localhost:5432/fresco_development
```

Override with `DATABASE_URL` or edit the file. To use SQLite instead,
swap the line to `Fresco.database :sqlite, path: …` and re-run
`bin/build`.

### 5. Run it

```sh
bin/dev
```

Open <http://localhost:3030/>. Edit files under `app/` or `config/` and
refresh — the dev loop rebuilds and reloads automatically.

To produce a static release binary:

```sh
bin/release
./build/app
```

## What's in here

### Routes (`config/routes.rb`)

A grab-bag of patterns demonstrating the router:

| Path                       | Demonstrates                          |
| -------------------------- | ------------------------------------- |
| `/`                        | Root route + a styled landing page    |
| `/readme`                  | Rendering long markdown-ish content   |
| `/headers`                 | Request header introspection          |
| `/crash`                   | Error rendering / 500 page            |
| `/db_smoke`, `/db_smoke_pg`| Adapter-specific DB sanity check      |
| `/users_smoke`, `/posts_smoke` | Generated model finders + writes  |
| `/tx_smoke`                | Transactions / rollback               |
| `/session`, `/session/flash` | Cookie session + flash messages     |
| `/filters`                 | Before/after action filters           |
| `/files/*path`             | Splat captures + file streaming       |
| `/about(/:section)`        | Optional path segments                |
| `resources :users`         | Index/show convention                 |
| `resources :bookmarks`     | Full CRUD                             |

### Models (`app/models/`)

`User`, `Post`, and `Bookmark` show the build-time model DSL — declared
once, codegen'd into `generated/models/` against whichever adapter
`config/database.rb` selects. See `db/schema.rb` for the table layouts.

### Views (`app/views/`)

ERB compiled through Herb at build time. Includes:

- A shared layout at `app/views/layouts/`
- Partials (`_footer_note.html.erb`, `shared/`)
- Per-resource view directories (`users/`, `bookmarks/`, `filters/`)

### Examples (`examples/`)

`examples/bookshelf/` is a slightly larger sample app that lives
alongside the tour routes for comparison.

## Commands

```
bin/dev      # dev loop (CRuby, auto-reload)
bin/build    # regenerate generated/ without running the server
bin/release  # AOT-compile via Spinel → build/app
```

## More

- Framework: <https://github.com/afomera/fresco>
- Spinel: <https://github.com/matz/spinel>
