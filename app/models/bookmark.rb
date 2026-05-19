Fresco.model :Bookmark, table: :bookmarks do
  finder :title
  validates :url, presence: true
end
