# Fresco: schema declaration. Loaded by `fresco build` to drive model
# codegen. Add tables with:
#
#   Fresco.schema do
#     table :users do
#       column :id, :int, primary_key: true
#       column :email, :str, null: false, index: :unique
#     end
#   end
#
# Runtime never loads this file — generated/models/*.rb are
# self-contained.
Fresco.schema do
end
