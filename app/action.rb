# App: shared base for all actions in this application.
#
# Inherits from Fresco::Action (defined in the runtime shim). This
# is the user-owned customization point — add helper methods, shared
# state, or app-wide filters here. Concrete actions under
# app/actions/ should `< App::Action` rather than inheriting
# Fresco::Action directly, so cross-cutting changes stay in one
# file.
#
# Filters available from the framework base:
#   - #before_action(req)      — override to run pre-call code; call
#                                halt!(resp) to short-circuit #call.
#   - #after_action(req, res)  — override to run post-call code; call
#                                halt!(resp) to replace the response.
#   - #handle(req) + super     — wrap the whole pipeline ("around").

module App
  class Action < Fresco::Action
    # Default layout for every app action. Override `#layout` on a
    # specific action class (or return :none) to opt out per-action.
    def layout
      :application
    end
  end
end
