# Shared base for all actions in this application. Concrete actions
# under app/actions/ inherit from this rather than Fresco::Action
# directly, so cross-cutting changes (layouts, filters, helper
# methods) stay in one place.
#
# Filters available from the framework base:
#   - #before_action(req)      — override to run pre-call code; call
#                                halt!(resp) to short-circuit #call.
#   - #after_action(req, res)  — override to run post-call code; call
#                                halt!(resp) to replace the response.
#   - #handle(req) + super     — wrap the whole pipeline ("around").
module Bookshelf
  class Action < Fresco::Action
    # Default layout for every action. Override `#layout` on a
    # specific action class (or return :none) to opt out per-action.
    def layout
      :application
    end
  end
end
