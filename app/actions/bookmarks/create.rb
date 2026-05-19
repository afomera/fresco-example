module Bookmarks
  class Create < App::Action
    # POST /bookmarks. The model's `validates :url, presence: true`
    # short-circuits to -1 on a blank url before any DB roundtrip, so
    # we don't pre-validate here — a single check on the return id
    # covers both the validation case and a genuine insert failure.
    # created_at is filled in server-side; the form doesn't ship one.
    def call(req)
      url   = req.params.str(:url)
      title = req.params.str(:title)

      new_id = Bookmark.insert(url: url, title: title, created_at: Time.now.to_i)
      if new_id < 0
        req.flash.set("error", "url is required")
        return redirect_to("/bookmarks/new")
      end

      req.flash.set("notice", "Bookmark created")
      redirect_to("/bookmarks/" + new_id.to_s)
    end
  end
end
