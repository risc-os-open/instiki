require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Beast
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    #
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    #
    config.autoload_lib(ignore: %w(assets tasks))

    Rails.autoloaders.each do |autoloader|
      autoloader.inflector.inflect(
        'dnsbl_check' => 'DNSBL_Check',
        'xhtml_diff'  => 'XHTMLDiff',
      )
    end

    # Permitted hosts.
    #
    config.hosts << "epsilon.arachsys.com"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone                      = 'UTC'
    config.active_record.default_timezone = :utc

  end
end
