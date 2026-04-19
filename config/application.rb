require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HomeFinance
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Support Home Assistant ingress: the entrypoint sets RAILS_RELATIVE_URL_ROOT
    # to the dynamic ingress path so all generated URLs are correctly prefixed.
    config.relative_url_root = ENV["RAILS_RELATIVE_URL_ROOT"] if ENV["RAILS_RELATIVE_URL_ROOT"].present?

    # When running as a Home Assistant add-on the ingress proxy forwards each request
    # with an X-Ingress-Path header containing the dynamic path prefix (e.g.
    # /api/hassio_ingress/<token>).  Setting SCRIPT_NAME on the Rack env makes Rails
    # route helpers include that prefix in every generated URL so that navigation
    # links work correctly inside the HA frontend.
    require_relative "../app/middleware/home_assistant_ingress_middleware"
    config.middleware.use HomeAssistantIngressMiddleware
  end
end
