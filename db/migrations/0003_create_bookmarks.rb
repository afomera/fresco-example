Fresco.migration "0003_create_bookmarks" do
  up do
    if Fresco.database_adapter == :postgres
      sql "CREATE TABLE bookmarks (id SERIAL PRIMARY KEY, url TEXT NOT NULL, title TEXT, created_at INTEGER)"
    else
      sql "CREATE TABLE bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT NOT NULL, title TEXT, created_at INTEGER)"
    end
  end

  down do
    sql "DROP TABLE bookmarks"
  end
end
