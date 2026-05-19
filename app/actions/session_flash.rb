# GET /session/flash — set a one-shot flash message, then point the
# user back to /session so they can see it consumed.
#
# Real apps would redirect (302) after a state change; until the
# framework grows redirects, a plain text response carrying the
# instructions is enough to demonstrate flash semantics.
class SessionFlash < App::Action
  def call(req)
    req.flash.set("notice", "Hello from /session/flash!")
    req.flash.set("error", "Hello from /session/flash error!")
    redirect_to("/")
  end
end
