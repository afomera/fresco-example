# GET /session — exercise the signed-cookie session + flash.
#
# Tracks a visit counter that lives in the session; surfaces any flash
# notice set on the previous request. Plain text response so it's
# trivially curlable:
#
#   curl -c jar.txt -b jar.txt http://localhost:3000/session
#   curl -c jar.txt -b jar.txt http://localhost:3000/session/flash
#   curl -c jar.txt -b jar.txt http://localhost:3000/session    # shows flash + count
#   curl -c jar.txt -b jar.txt http://localhost:3000/session    # flash is gone
class SessionShow < App::Action
  def layout
    :none
  end

  def call(req)
    prev   = req.session.get("visits")
    visits = prev.length > 0 ? prev.to_i + 1 : 1
    req.session.set("visits", visits.to_s)

    body = "visits: " + visits.to_s + "\n"
    notice = req.flash.get("notice")
    if notice.length > 0
      body += "flash:  " + notice + "\n"
    end
    body += "\nGET /session/flash to set a one-shot flash, then GET /session again.\n"
    Response.text(200, body)
  end
end
