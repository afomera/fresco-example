# Fresco: route definitions.
#
# Evaluated by bin/build under CRuby. The block captures (verb, pattern,
# action_class) triples on Fresco.app.routes; bin/build emits
# generated/dispatch.rb from them. Not loaded at runtime —
# production reads the generated dispatcher.

Fresco.app.routes do
  root                      to: RootPath
  get "/readme",            to: Readme::Show
  get "/headers",           to: Headers::Show
  get "/crash",             to: Crash::Show
  get "/db_smoke",          to: DbSmoke
  get "/db_smoke_pg",       to: DbSmokePg
  get "/users_smoke",       to: UsersSmoke
  get "/posts_smoke",       to: PostsSmoke
  get "/tx_smoke",          to: TxSmoke
  get "/session",           to: SessionShow
  get "/session/flash",     to: SessionFlash
  get "/filters",           to: Filters::Show
  get "/files/*path",       to: Files::Show
  get "/about(/:section)",  to: About::Show
  resources :users,         only: [:index, :show]
  resources :bookmarks
end
