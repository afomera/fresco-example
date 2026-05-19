# Fresco: User model declaration. Build-time only — bin/build reads
# this to emit generated/models/user.rb, which is what gets
# loaded into the running binary. The class itself is materialised by
# codegen, not by this file.
#
# `finder :email` declares that a `User.where_email(email)` class
# method should be generated, backed by a single typed finder query.
# Each finder costs nothing if unused, but every indexed column you
# want a finder for has to be declared here — there is no dynamic
# `User.where(hash)` (poly-hash dispatch widens to RbVal).

Fresco.model :User, table: :users do
  finder :email
  finder :name
end
