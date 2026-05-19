module Bookmarks
  class Edit < App::Action
    # GET /bookmarks/:id/edit — same lookup as Show; the template
    # branches on `found?` and prefills the form with the existing
    # url/title, or renders a 404-ish "not found" notice.
    def call(req)
      render(render_bookmarks_edit(bookmark: Bookmark.find(req.params.int(:id))))
    end
  end
end
