# M3 smoke test for the generated User model. Exercises every method
# the codegen emits: insert (returns new id), find (by PK, hit + miss),
# where_email (Array<User>), where_name (Array<User>), all, #update,
# #delete. Returns a multi-line text summary so a CLI run (or curl)
# can eyeball each step.
#
# Self-bootstrapping: runs CREATE TABLE IF NOT EXISTS up front via
# Fresco::Db.exec so the action works on a fresh DB. M5 migrations
# will subsume this — for now each model-touching smoke test owns
# its own DDL.
class UsersSmoke < App::Action
  def layout
    :none
  end

  def call(req = Request.new("", "", ""))
    return ddl_error unless setup_table

    # Re-running the smoke against an existing table is safe; we
    # delete first so insert ids start fresh each call. (DELETE
    # rather than TRUNCATE because the DDL is portable; M4+ may add
    # adapter-specific helpers.)
    #
    # posts has a foreign key on users — under Postgres, DELETE FROM
    # users would fail with a FK violation if posts referenced any
    # of these users. Clear posts first so users can be cleared
    # cleanly. SQLite's FK enforcement is opt-in via PRAGMA, so this
    # is mostly a no-op there; either way the ordering is safe.
    Fresco::Db.exec("DELETE FROM posts")
    Fresco::Db.exec("DELETE FROM users")

    new_id = User.insert(email: "alice@example.com", name: "Alice", created_at: 1700000000)
    return Response.text(500, "insert failed\n") if new_id < 0

    alice = User.find(new_id)
    return Response.text(500, "find missed\n") unless alice.found?

    miss = User.find(999999)
    return Response.text(500, "miss should be unfound\n") if miss.found?

    User.insert(email: "bob@example.com",   name: "Bob",   created_at: 1700000001)
    User.insert(email: "carol@example.com", name: "Carol", created_at: 1700000002)

    by_email = User.where_email("bob@example.com")
    return Response.text(500, "where_email miss\n") if by_email.length != 1
    bob = by_email[0]

    by_name = User.where_name("Carol")
    return Response.text(500, "where_name miss\n") if by_name.length != 1
    carol = by_name[0]

    all = User.all
    return Response.text(500, "all wrong count " + all.length.to_s + "\n") if all.length != 3

    # Mutate Bob and re-read to confirm update wrote through.
    bob.update(email: "bob@new.example.com", name: "Bob Two", created_at: bob.created_at)
    bob_re = User.find(bob.id)
    return Response.text(500, "update lost\n") unless bob_re.email == "bob@new.example.com"

    # Delete Carol and confirm she's gone.
    carol.delete
    after_delete = User.all
    return Response.text(500, "delete lost\n") if after_delete.length != 2

    # M6 surface: find_by_<unique col>, count, count_where_<col>.
    alice_by_email = User.find_by_email("alice@example.com")
    return Response.text(500, "find_by_email missed\n") unless alice_by_email.found?
    miss_by_email = User.find_by_email("nobody@example.com")
    return Response.text(500, "find_by_email miss should be unfound\n") if miss_by_email.found?

    total = User.count
    return Response.text(500, "count wrong " + total.to_s + "\n") unless total == 2

    alice_count = User.count_where_email("alice@example.com")
    return Response.text(500, "count_where_email wrong " + alice_count.to_s + "\n") unless alice_count == 1

    out = "ok\n"
    out += "  insert id=" + alice.id.to_s + " email=" + alice.email + "\n"
    out += "  find hit=" + alice.found?.to_s + " miss=" + miss.found?.to_s + "\n"
    out += "  where_email -> " + by_email.length.to_s + " row(s)\n"
    out += "  where_name  -> " + by_name.length.to_s + " row(s)\n"
    out += "  after insert all=" + all.length.to_s + "\n"
    out += "  after update bob.email=" + bob_re.email + "\n"
    out += "  after delete all=" + after_delete.length.to_s + "\n"
    out += "  find_by_email alice.email=" + alice_by_email.email + "\n"
    out += "  count=" + total.to_s + " count_where_email(alice)=" + alice_count.to_s + "\n"
    Response.text(200, out)
  end

  # Per-adapter CREATE TABLE so the smoke is self-contained. The
  # schema mirrors what db/schema.rb declares — bin/build doesn't
  # emit DDL yet (M5 migrations) so we hand-write it here. Drift
  # between this and the model codegen would surface as missing-column
  # errors at runtime.
  def setup_table
    adapter = Fresco.database_adapter
    if adapter == :postgres
      Fresco::Db.exec("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, email TEXT NOT NULL UNIQUE, name TEXT, created_at INTEGER)")
    else
      Fresco::Db.exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL UNIQUE, name TEXT, created_at INTEGER)")
    end
  end

  def ddl_error
    Response.text(500, "setup_table failed (" + Fresco.database_adapter.to_s + ")\n")
  end
end
