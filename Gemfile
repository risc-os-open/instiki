source 'https://rubygems.org'

gem 'rails', '~> 8.0'

# Use PostgresSQL as the database for Active Record
#
gem 'pg', '~> 1.5'

# Use the Puma web server [https://github.com/puma/puma]
#
gem 'puma', '~> 6.0'

# This isn't part of Ruby anymore.
#
gem 'ostruct', '~> 0.6'

# For Windows or esoteric Unix/Linux-like distributions.
#
gem 'tzinfo-data'

# Use SCSS for stylesheets via a robust preprocessing step [https://rubygems.org/gems/cssbundling-rails/]
#
gem 'cssbundling-rails' # ...using whatever version Rails wants

# Use a robust preprocessing step for JavaScript, too; this lets us manage any
# components available in NPM that have both JS and CSS components using the
# same mechanism (Yarn) [https://rubygems.org/gems/jsbundling-rails/]
#
gem 'jsbundling-rails' # ...using whatever version Rails wants

# Rails 7+ 'modern' asset pipeline [https://rubygems.org/gems/propshaft]
#
gem 'propshaft', '~> 1.1'

# Use Hub for authentication [https://github.com/pond/hubssolib]
#
gem 'hubssolib', '~> 2.1', require: 'hub_sso_lib'

# Easy pagination [https://rubygems.org/gems/pagy]
#
gem 'pagy', '~> 9.3'

# Textile support [https://rubygems.org/gems/RedCloth]
#
gem 'RedCloth', '~> 4.3'

# Markdown with GFM extensions etc. [https://rubygems.org/gems/commonmarker]
#
gem 'commonmarker', '~> 2.0'

# Wider support for markup formats [https://rubygems.org/gems/github-markup]
#
gem 'github-markup', '~> 5.0'

# HTML processing [https://rubygems.org/gems/html-pipeline]
#
gem 'html-pipeline', '~> 3.2'

# Replace Rails <= 3.0 'auto_link' [https://rubygems.org/gems/rails_autolink]
#
gem 'rails_autolink', '~> 1.1'

# List positioning [https://rubygems.org/gems/acts_as_list]
#
gem 'acts_as_list', '~> 1.2'

# XML / HTML processing for things like diffs...
#
gem 'rexml', '~> 3.4'

# ...and the underlying diff processor.
#
gem 'diff-lcs', '~> 1.5'

# RSS (XML) feed building is done via Builder.
#
gem 'builder', '~> 3.3'

group :development, :test do

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  #
  gem 'debug', platforms: %i[ mri windows ]

end

# Monitoring and alerting [http://rubygems.org/gems/newrelic_rpm]
#
gem 'newrelic_rpm'

group :development do

  # Use console on exceptions pages [https://github.com/rails/web-console]
  #
  gem 'web-console'

  # Be able to run 'bin/dev'
  #
  gem 'foreman'

  # E-mail inspection.
  #
  gem 'mailcatcher'

  # Make generated SQL a little easier to read, where needed:
  #
  #   puts Niceql::Prettifier.prettify_sql(some_ar_statement.to_sql)
  #
  gem 'niceql', '~> 0.6'

end

group :test do

  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  #
  gem 'capybara'
  gem 'selenium-webdriver'

end
