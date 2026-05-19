module About
  class Show < App::Action
    def call(req)
      section = req.params[:section]
      if section.empty?
        Response.text(200, "About\n")
      else
        Response.text(200, "About: #{section}\n")
      end
    end
  end
end
