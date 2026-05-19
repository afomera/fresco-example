# M4 smoke test for the generated Post model. Exercises the new M4
# surface: :bool column, foreign-key column, validates :presence
# guard. Same shape as /users_smoke — self-bootstrapping DDL, deletes
# rows first so the run is idempotent, returns a multi-line summary.
class PostsSmoke < App::Action
  def layout
    :none
  end

  def call(req = Request.new("", "", ""))
    return ddl_error unless setup_table

    Fresco::Db.exec("DELETE FROM posts")
    Fresco::Db.exec("DELETE FROM users")

    # Create two users first; FK constraint on posts.user_id REFERENCES
    # users(id) means we can't insert posts with dangling ids. SERIAL
    # ids are not guaranteed to start at 1 (the sequence persists across
    # truncates), so we capture the actual ids returned by insert.
    user_a = User.insert(email: "author-a@example.com", name: "Author A", created_at: 1700000000)
    user_b = User.insert(email: "author-b@example.com", name: "Author B", created_at: 1700000001)
    return Response.text(500, "user insert failed\n") if user_a < 0 || user_b < 0

    # presence: true on :title should reject an empty-string insert
    # before any DB roundtrip. Returns -1.
    rejected = Post.insert(user_id: user_a, title: "", body: "no title", published: false)
    return Response.text(500, "validation didn't reject empty title (got " + rejected.to_s + ")\n") unless rejected == -1

    # Valid insert: id assigned, :bool round-trips through bind_int.
    post_id = Post.insert(user_id: user_a, title: "Hello", body: "First post", published: true)
    return Response.text(500, "insert failed\n") if post_id < 0

    p = Post.find(post_id)
    return Response.text(500, "find missed\n") unless p.found?
    return Response.text(500, "bool round-trip failed (published=" + p.published.to_s + ")\n") unless p.published

    Post.insert(user_id: user_a, title: "Draft",        body: "Not yet ready",  published: false)
    Post.insert(user_id: user_b, title: "Other author", body: "Different user", published: true)

    # Finder by FK column (:int). Two posts from user_a.
    by_user = Post.where_user_id(user_a)
    return Response.text(500, "where_user_id wrong count " + by_user.length.to_s + "\n") unless by_user.length == 2

    # Finder by :bool column (codegen wraps the bind in the ternary).
    published = Post.where_published(true)
    return Response.text(500, "where_published wrong count " + published.length.to_s + "\n") unless published.length == 2

    # #update with the same validation — empty title rejected on
    # update too. Existing row stays untouched.
    p_re = Post.find(post_id)
    accepted = p_re.update(user_id: p_re.user_id, title: "", body: "tried to blank the title", published: p_re.published)
    return Response.text(500, "update accepted empty title\n") if accepted == false ? false : true
    # accepted == false means the validation rejected; we want that.
    p_after = Post.find(post_id)
    return Response.text(500, "update mutated despite validation (title=" + p_after.title + ")\n") unless p_after.title == "Hello"

    out = "ok\n"
    out += "  rejected empty-title insert: id=" + rejected.to_s + "\n"
    out += "  valid insert id=" + p.id.to_s + " title=" + p.title + " published=" + p.published.to_s + "\n"
    out += "  where_user_id(1)  -> " + by_user.length.to_s + " row(s)\n"
    out += "  where_published(true) -> " + published.length.to_s + " row(s)\n"
    out += "  validation kept title=" + p_after.title + "\n"
    Response.text(200, out)
  end

  def setup_table
    adapter = Fresco.database_adapter
    if adapter == :postgres
      Fresco::Db.exec("CREATE TABLE IF NOT EXISTS posts (id SERIAL PRIMARY KEY, user_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT, published BOOLEAN)")
    else
      Fresco::Db.exec("CREATE TABLE IF NOT EXISTS posts (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT, published INTEGER)")
    end
  end

  def ddl_error
    Response.text(500, "setup_table failed (" + Fresco.database_adapter.to_s + ")\n")
  end
end
