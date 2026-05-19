module Crash
  class Show < App::Action
    def call(req = Request.new("", "", ""))
      raise "intentional crash for M6 smoke test"
      # Tells Spinel's return-type inference that this method returns
      # Response just like every other action — the raise above takes
      # the actual control path.
      Response.text(500, "unreached")
    end
  end
end
