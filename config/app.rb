# App: boot-time customization point.
#
# In a generated app, `App` would be replaced by the user's chosen
# top-level namespace (e.g. `Bookshelf::Base < Fresco::App`,
# Hanami-style). This file is where defaults like port/workers or
# eventual config DSLs get overridden — App::Base.new is instantiated
# from app.rb at startup, so anything set in #initialize takes effect
# before the listener spawns.

# Sign signed-session cookies (and anything else that uses HMAC) with
# the value of $SESSION_SECRET. Falls back to a placeholder for the
# dev loop so /session works out of the box; production deployments
# MUST set the env var to a long random string (e.g. 64 hex bytes
# from `openssl rand -hex 32`). Empty value silently disables
# sessions entirely.
#
# Split the ENV read from the assignment instead of `ENV.fetch(key,
# default)`: Spinel's two-arg `ENV.fetch` codegen emits a `const
# char *` ternary but the surrounding context wraps the result in
# `sp_box_str`, producing an "assigning to 'const char *' from
# incompatible type 'sp_RbVal'" compile error at the setter site.
session_secret = ENV["SESSION_SECRET"]
if session_secret.nil? || session_secret.empty?
  session_secret = "dev-only-INSECURE-session-secret-change-me-for-prod"
end
Fresco.set_session_secret(session_secret)

module App
  class Base < Fresco::App
  end
end
