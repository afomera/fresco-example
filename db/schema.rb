# Fresco: schema declaration. Read by bin/build to drive model
# codegen and (M5+) the embedded migration runner. Generated models
# under generated/models/*.rb embed adapter-specific SQL based on
# what this file declares — switching adapters (config/database.rb)
# requires a rebuild but no source edits here.
#
# Column type → adapter type mapping:
#   :int   → INTEGER  (SQLite) / INTEGER  (Postgres)
#   :str   → TEXT     (SQLite) / TEXT     (Postgres)
#   :bool  → INTEGER  (SQLite) / BOOLEAN  (Postgres)  -- M4+
#   :float → REAL     (SQLite) / DOUBLE PRECISION (Postgres)
#
# Opts:
#   primary_key: true            -- PK (one per table)
#   null:        false           -- NOT NULL
#   index:       :unique         -- unique index on the column
#   default:     <literal|proc>  -- M4+ default value
#   references:  :other_table    -- foreign key (M4+)

Fresco.schema do
  table :users do
    column :id,         :int, primary_key: true
    column :email,      :str, null: false, index: :unique
    column :name,       :str
    column :created_at, :int
  end

  table :posts do
    column :id,        :int,  primary_key: true
    column :user_id,   :int,  null: false
    column :title,     :str,  null: false
    column :body,      :str
    column :published, :bool
    foreign_key :user_id, references: :users
  end

  table :bookmarks do
    column :id,         :int, primary_key: true
    column :url,        :str, null: false
    column :title,      :str
    column :created_at, :int
  end
end
