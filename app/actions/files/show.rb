module Files
  class Show < App::Action
    ROOT = "public".freeze

    def call(req)
      file_response(req.params[:path], ROOT)
    end
  end
end
