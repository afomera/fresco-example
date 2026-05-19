module Headers
  class Show < App::Action
    def call(req)
      ua = "(none)"
      if req.headers.key?("user-agent")
        ua = req.headers["user-agent"]
      end
      Response.text(200, "user-agent: " + ua + "\n")
    end
  end
end
