class RootPath < App::Action
  def call(req = Request.new("", "", ""))
    render(render_root_path)
  end
end
