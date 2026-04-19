require "test_helper"

class HomeAssistantIngressMiddlewareTest < ActiveSupport::TestCase
  setup do
    @app = ->(env) { [ 200, {}, [ env["SCRIPT_NAME"].to_s ] ] }
    @middleware = HomeAssistantIngressMiddleware.new(@app)
  end

  test "sets SCRIPT_NAME from X-Ingress-Path header" do
    env = { "HTTP_X_INGRESS_PATH" => "/api/hassio_ingress/abc123" }
    @middleware.call(env)
    assert_equal "/api/hassio_ingress/abc123", env["SCRIPT_NAME"]
  end

  test "does not set SCRIPT_NAME when X-Ingress-Path header is absent" do
    env = {}
    @middleware.call(env)
    assert_nil env["SCRIPT_NAME"]
  end

  test "does not set SCRIPT_NAME when X-Ingress-Path header is blank" do
    env = { "HTTP_X_INGRESS_PATH" => "" }
    @middleware.call(env)
    assert_nil env["SCRIPT_NAME"]
  end

  test "calls the next middleware" do
    env = { "HTTP_X_INGRESS_PATH" => "/api/hassio_ingress/abc123" }
    status, _headers, body = @middleware.call(env)
    assert_equal 200, status
    assert_equal [ "/api/hassio_ingress/abc123" ], body
  end
end
