module Bookmarks
  class New < App::Action
    # GET /bookmarks/new — empty form. The template doesn't need any
    # locals (it just hardcodes the form action + method), but we
    # render via the layout so flash messages from a failed create
    # surface here on the redirect-back path.
    def call(req = Request.new("", "", ""))
      render(render_bookmarks_new)
    end
  end
end
