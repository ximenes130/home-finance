class HomeAssistantIngressMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if (ingress_path = env["HTTP_X_INGRESS_PATH"].presence)
      env["SCRIPT_NAME"] = ingress_path
    end

    @app.call(env)
  end
end
