# Fresco: Post model declaration. Build-time only; bin/build reads
# this to emit generated/models/post.rb. The user_id column is a
# foreign key to users (declared in db/schema.rb) — M4 captures that
# metadata but doesn't generate any join helpers from it yet (M6+).
#
# `validates :title, presence: true` emits a top-of-method guard
# inside .insert and #update: empty-string titles short-circuit
# before any DB roundtrip. Same shape as ActiveModel's terse case.

Fresco.model :Post, table: :posts do
  finder :user_id
  finder :published
  validates :title, presence: true
end
