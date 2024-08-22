source 'https://rubygems.org'

ruby '3.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 7.1.3', '>= 7.1.3.3'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails', :require => 'sprockets/railtie'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.7'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Use Hub for authentication [https://github.com/pond/hubssolib]
#
gem 'hubssolib', '~> 2.0', require: 'hub_sso_lib'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem 'kredis'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem 'bcrypt', '~> 3.1.7'

gem 'tzinfo-data'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Easy pagination [https://rubygems.org/gems/pagy]
#
gem 'pagy', '~> 9.0'

# Textile support [https://rubygems.org/gems/RedCloth]
#
gem 'RedCloth', '~> 4.3'

# Markdown with GFM extensions etc. [https://rubygems.org/gems/commonmarker]
#
gem 'commonmarker', '~> 1.1'

# Wider support for markup formats [https://rubygems.org/gems/github-markup]
#
gem 'github-markup', '~> 5.0'

# HTML processing [https://rubygems.org/gems/html-pipeline]
#
# TODO: v3.2.1 breaks everything; see
#
gem 'html-pipeline', '= 3.2.0'

# Replace Rails <= 3.0 'auto_link' [https://rubygems.org/gems/rails_autolink]
#
gem 'rails_autolink', '~> 1.1'

# List positioning [https://rubygems.org/gems/acts_as_list]
#
gem 'acts_as_list', '~> 1.2'

# XML / HTML processing for things like diffs...
#
gem 'rexml', '~> 3.3'

# ...and the underlying diff processor.
#
gem 'diff-lcs', '~> 1.5'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem 'rack-mini-profiler'

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem 'spring'

  gem 'error_highlight', '>= 0.4.0', platforms: [:ruby]
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'selenium-webdriver'
end
