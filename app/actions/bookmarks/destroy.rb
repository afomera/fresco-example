module Bookmarks
  class Destroy < App::Action
    # DELETE /bookmarks/:id (form override: `_method=delete`).
    # Idempotent — a missing id still redirects with a flash so a
    # double-click from the index doesn't 404 the second click.
    def call(req)
      bookmark = Bookmark.find(req.params.int(:id))
      if bookmark.found?
        bookmark.delete
        req.flash.set("notice", "Bookmark deleted")
      else
        req.flash.set("error", "Bookmark not found")
      end
      redirect_to("/bookmarks")
    end
  end
end
