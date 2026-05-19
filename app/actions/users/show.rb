module Users
  class Show < App::Action
    def call(req)
      render(render_users_show(id: req.params[:id]))
    end
  end
end
