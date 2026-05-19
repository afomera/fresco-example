# GET /filters — demo of Fresco::Action's filter pipeline.
#
# Exercises all three hooks the base class supports:
#   - #before_action  bumps a session-tracked visit counter, then
#     halts the chain with a flash redirect when the request carries
#     `?halt=1` (lets users trigger the short-circuit on demand).
#   - #after_action   stamps the session with the visit count just
#     seen — the response body is already built by then, so this
#     only affects the *next* request's display, which is the
#     easiest way to see the hook actually ran.
#   - "Around" via #handle + super  brackets the entire pipeline
#     to log how long it took, the way an instrumentation filter
#     would.
module Filters
  class Show < App::Action
    def before_action(req)
      visits = req.session.get("filter_visits").to_i + 1
      req.session.set("filter_visits", visits.to_s)

      if req.params.str(:halt) == "1"
        req.flash.set("notice", "before_action halted! No #call was run.")
        halt!(redirect_to("/filters"))
      end
    end

    def call(req)
      visits   = req.session.get("filter_visits")
      last_ack = req.session.get("filter_last_ack")
      render(render_filters_show(visits: visits, last_ack: last_ack))
    end

    def after_action(req, _res)
      req.session.set("filter_last_ack", req.session.get("filter_visits"))
    end

    # "Around" filter: override #handle, bracket the super call.
    # sphttp_mark_now / sphttp_elapsed_micros are the same primitives
    # the production server uses for request timing.
    #
    # Spinel quirk: `res = super` doesn't type-propagate the parent's
    # return through the local — the analyzer defaults `res` to
    # mrb_int. Priming `res` with a Response value first pins the
    # local to `sp_Response *`; the super assignment overwrites the
    # value without re-widening.
    def handle(req)
      Sock.sphttp_mark_now
      res = Response.text(0, "")
      res = super
      puts "[filters] /filters took " + Sock.sphttp_elapsed_micros.to_s + "us"
      res
    end
  end
end
