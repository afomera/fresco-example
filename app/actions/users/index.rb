module Users
  class Index < App::Action
    # Demonstrates the JSON encoder end-to-end. The payload is
    # `Hash<Symbol, *>` with scalar / Array<scalar> values; nesting a
    # Hash inside the Array would route through the polymorphic
    # `encode` path, which falls through to `to_s` because Spinel's
    # `.each` lowering can't iterate a polymorphic-typed hash (see
    # the `Spinel::Json` module header).
    def call(req = Request.new("", "", ""))
      Response.json(200, { count: 2, names: ["Andrea", "Bea"], ids: [1, 2] })
    end
  end
end
