# M5 transaction smoke test. Spinel doesn't lower `&block`-style
# Ruby DSLs cleanly, so transactions are driven by explicit
# begin_tx / commit_tx / rollback! primitives. This action
# exercises both branches:
#
#   1. Commit path: begin_tx, insert, commit_tx → row visible after.
#   2. Rollback path: begin_tx, insert, rollback!, commit_tx →
#      ROLLBACK runs instead of COMMIT, row stays gone.
#
# Assumes the users table already exists (run `./app db:migrate`
# first). Doesn't run CREATE TABLE — that's the migration's job
# in M5; smoke actions stop owning DDL.
class TxSmoke < App::Action
  def layout
    :none
  end

  def call(req = Request.new("", "", ""))
    Fresco::Db.exec("DELETE FROM users")
    baseline = User.all.length

    Fresco::Db.begin_tx
    User.insert(email: "commit@example.com", name: "Commit", created_at: 1700000010)
    commit_ok = Fresco::Db.commit_tx
    after_commit = User.all.length
    return Response.text(500, "commit didn't insert (count=" + after_commit.to_s + ")\n") unless after_commit == baseline + 1

    Fresco::Db.begin_tx
    User.insert(email: "rollback@example.com", name: "Rollback", created_at: 1700000011)
    Fresco::Db.rollback!
    rollback_ok = Fresco::Db.commit_tx
    after_rollback = User.all.length
    return Response.text(500, "rollback wasn't undone (count=" + after_rollback.to_s + ")\n") unless after_rollback == baseline + 1

    out = "ok\n"
    out += "  baseline="     + baseline.to_s       + "\n"
    out += "  commit_tx="    + commit_ok.to_s      + " after=" + after_commit.to_s   + "\n"
    out += "  rollback_tx="  + rollback_ok.to_s    + " after=" + after_rollback.to_s + "\n"
    Response.text(200, out)
  end
end
