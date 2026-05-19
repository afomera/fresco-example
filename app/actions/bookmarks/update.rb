module Bookmarks
  class Update < App::Action
    # PATCH /bookmarks/:id (form override: `_method=patch`). Load the
    # row through .find so missing-id paths take the not-found branch
    # instead of overwriting some other record. `#update` returns
    # false on validation failure (empty url) — same flash-redirect
    # shape as Create's failure path so the UX is symmetric.
    def call(req)
      bookmark = Bookmark.find(req.params.int(:id))
      unless bookmark.found?
        req.flash.set("error", "Bookmark not found")
        return redirect_to("/bookmarks")
      end

      url   = req.params.str(:url)
      title = req.params.str(:title)

      ok = bookmark.update(url: url, title: title, created_at: bookmark.created_at)
      unless ok
        req.flash.set("error", "url is required")
        return redirect_to("/bookmarks/" + bookmark.id.to_s + "/edit")
      end

      req.flash.set("notice", "Bookmark updated")
      redirect_to("/bookmarks/" + bookmark.id.to_s)
    end
  end
end
