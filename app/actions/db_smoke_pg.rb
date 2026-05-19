# Postgres-specific smoke test. Same end-state as /db_smoke under the
# Postgres adapter, but adds a CREATE-DATABASE fallback: if opening
# the configured URL fails (database missing), the action connects to
# the same server's `postgres` admin DB, runs `CREATE DATABASE`, and
# retries the open. Useful on fresh dev machines where the dev DB
# hasn't been provisioned yet.
#
# Uses `Fresco::Db.new_instance` rather than `Fresco::Db::Postgres.new`
# so the SQLite release build doesn't choke on a missing
# `Fresco::Db::Postgres` symbol — the adapter guard at the top of
# #call short-circuits cleanly under the SQLite adapter.
#
# URL parsing is intentionally shallow — we look for the last `/` to
# split host-and-creds from the database name. Query strings (e.g.
# `?sslmode=require`) aren't handled; document and revisit if it
# becomes a problem. The dbname is interpolated raw into the
# `CREATE DATABASE` statement — fine for dev URLs the developer owns,
# but not safe against untrusted input.
class DbSmokePg < App::Action
  def layout
    :none
  end

  def call(req = Request.new("", "", ""))
    if Fresco.database_adapter != :postgres
      return Response.text(
        400,
        "this route requires the postgres adapter; configured: " +
          Fresco.database_adapter.to_s + "\n",
      )
    end

    url = Fresco.database_url
    return Response.text(500, "no postgres url configured\n") if url.length == 0

    db = Fresco::Db.new_instance
    unless db.open(url)
      # Open failed — most common reason on a fresh machine is the
      # target database doesn't exist yet. Try to create it.
      unless ensure_database!(url)
        return Response.text(500, "open failed and create-db fallback failed\n")
      end
      return Response.text(500, "open failed after CREATE DATABASE\n") unless db.open(url)
    end

    unless db.exec("CREATE TABLE IF NOT EXISTS db_smoke_notes (id SERIAL PRIMARY KEY, body TEXT)")
      db.close
      return Response.text(500, "create table failed\n")
    end

    cid = db.prepare("INSERT INTO db_smoke_notes (body) VALUES ($1) RETURNING id")
    if cid < 0
      db.close
      return Response.text(500, "prepare failed\n")
    end
    db.bind_str(cid, 1, "hello from postgres")
    rowid = 0
    if db.step(cid) == 1
      rowid = db.col_int(cid, 0)
    end
    db.finalize(cid)

    body = db.first_str("SELECT body FROM db_smoke_notes WHERE id = $1", rowid.to_s)
    db.close

    Response.text(200, body + " (rowid=" + rowid.to_s + ")\n")
  end

  # Connect to the postgres admin DB on the same server and CREATE
  # DATABASE the target. Returns true on success. Postgres has no
  # `CREATE DATABASE IF NOT EXISTS`, so this also returns true when
  # the create fails — the caller's subsequent open() retry tells us
  # whether the DB actually exists.
  def ensure_database!(url = "")
    slash = str_ridx(url, "/")
    return false if slash < 0
    dbname     = url[slash + 1, url.length - slash - 1]
    parent_url = url[0, slash + 1] + "postgres"

    parent = Fresco::Db.new_instance
    return false unless parent.open(parent_url)
    parent.exec("CREATE DATABASE " + dbname)
    parent.close
    true
  end
end
