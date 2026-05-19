module Readme
  class Show < App::Action
    def call(req = Request.new("", "", ""))
      Response.markdown(200, "# Readme\n\nMVP framework.\n")
    end
  end
end
