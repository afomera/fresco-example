module Bookmarks
  class Index < App::Action
    # GET /bookmarks — list every row, oldest id first (Bookmark.all is
    # PK-ordered). The view iterates the Array<Bookmark> the model
    # returns; we pass it through so the analyzer pins the type at the
    # call boundary instead of re-deriving it inside the template.
    def call(req = Request.new("", "", ""))
      render(render_bookmarks_index(bookmarks: Bookmark.all))
    end
  end
end
