module Bookmarks
  class Show < App::Action
    # GET /bookmarks/:id — Bookmark.find always returns a Bookmark
    # instance (missing rows come back with `found?` false rather than
    # nil — return-type unions widen the dispatch chain to RbVal). We
    # let the view branch on found? so the 200/404 distinction lives
    # in one place, the template.
    def call(req)
      render(render_bookmarks_show(bookmark: Bookmark.find(req.params.int(:id))))
    end
  end
end
