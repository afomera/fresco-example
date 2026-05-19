# DB-agnostic smoke test. Works under whichever adapter
# config/database.rb selected. `Fresco::Db.new_instance` returns a
# fresh adapter instance with a Spinel-resolvable concrete type — the
# `Active` alias confuses Spinel's analyzer (constant aliases aren't
# chased), so the factory exists specifically to give the analyzer a
# typed return to bind dispatch against.
#
# SQL syntax differs per adapter — placeholders (`?` vs `$1`),
# autoincrement keyword (`INTEGER PRIMARY KEY` is monotonic on its own
# in SQLite; Postgres needs `SERIAL`), and the new-id retrieval pattern
# (`last_rowid` vs `RETURNING id`). The action pre-builds the strings
# once per request so the main flow stays linear.
class DbSmoke < App::Action
  def layout
    :none # plain text — no app layout
  end

  def call(req = Request.new("", "", ""))
    adapter = Fresco.database_adapter
    return Response.text(500, "no database configured\n") if adapter == :none

    # SQLite uses :path, Postgres uses :url. Pull the right typed
    # scalar — avoids the SymPolyHash trap a single config hash would
    # have introduced.
    dsn = adapter == :postgres ? Fresco.database_url : Fresco.database_path
    return Response.text(500, "no dsn configured for " + adapter.to_s + "\n") if dsn.length == 0

    db = Fresco::Db.new_instance
    return Response.text(500, "open failed (" + adapter.to_s + ")\n") unless db.open(dsn)

    if adapter == :postgres
      ddl = "CREATE TABLE IF NOT EXISTS db_smoke_notes (id SERIAL PRIMARY KEY, body TEXT)"
      ins = "INSERT INTO db_smoke_notes (body) VALUES ($1) RETURNING id"
      sel = "SELECT body FROM db_smoke_notes WHERE id = $1"
    else
      ddl = "CREATE TABLE IF NOT EXISTS db_smoke_notes (id INTEGER PRIMARY KEY AUTOINCREMENT, body TEXT)"
      ins = "INSERT INTO db_smoke_notes (body) VALUES (?)"
      sel = "SELECT body FROM db_smoke_notes WHERE id = ?"
    end

    unless db.exec(ddl)
      db.close
      return Response.text(500, "create failed\n")
    end

    cid = db.prepare(ins)
    if cid < 0
      db.close
      return Response.text(500, "prepare failed\n")
    end
    db.bind_str(cid, 1, "hello from " + adapter.to_s)

    rowid = 0
    if adapter == :postgres
      # RETURNING id makes step yield one row with the new id in col 0.
      # No second roundtrip through SELECT lastval(); we read the id
      # directly off the INSERT cursor.
      if db.step(cid) == 1
        rowid = db.col_int(cid, 0)
      end
    else
      # SQLite path: step consumes the INSERT (no rows returned),
      # then last_rowid pulls the auto-assigned id off the connection.
      db.step(cid)
    end
    db.finalize(cid)
    rowid = db.last_rowid if adapter != :postgres

    body = db.first_str(sel, rowid.to_s)
    db.close

    Response.text(200, body + " (rowid=" + rowid.to_s + ")\n")
  end
end
