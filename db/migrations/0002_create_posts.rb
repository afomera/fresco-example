Fresco.migration "0002_create_posts" do
  up do
    if Fresco.database_adapter == :postgres
      sql "CREATE TABLE posts (id SERIAL PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id), title TEXT NOT NULL, body TEXT, published BOOLEAN)"
    else
      sql "CREATE TABLE posts (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT, published INTEGER, FOREIGN KEY (user_id) REFERENCES users(id))"
    end
  end

  down do
    sql "DROP TABLE posts"
  end
end
