# This must be done here rather than environment.rb so that it gets picked up
# properly in Development mode, when the controller is re-read for each request
# but the environment may not be (e.g. it isn't with Passenger).

class ApplicationController < ActionController::Base
  include Pagy::Backend

  # See 'lib/dnsbl_check.rb'.
  #
  require_relative '../../lib/dnsbl_check.rb'
  include DNSBL_Check

  # Hub single sign-on support. Run the Hub filters for all actions to ensure
  # activity timeouts etc. work properly. The login integration with Hub is
  # done using modifications to the forum's own mechanism in
  # 'lib/authentication_system.rb'.
  #
  require 'hub_sso_lib'
  include HubSsoLib::Core

  before_action :hubssolib_beforehand
  after_action  :hubssolib_afterwards

  # Rescue all exceptions (bad form) to rotate the Hub key (good) and render or
  # raise the exception again (rapid reload for default handling).
  #
  rescue_from ::Exception, with: :on_error_rotate_and_raise

  # See ActionController::RequestForgeryProtection for details.
  protect_from_forgery

  before_action :connect_to_model, :check_authorization, :setup_url_generator, :set_content_type_header, :set_robots_metatag
  after_action  :remember_location, :teardown_url_generator

  helper_method :darken

  FILE_TYPES = {
    '.aif'  => 'audio/x-aiff',
    '.aiff' => 'audio/x-aiff',
    '.avi'  => 'video/x-msvideo',
    '.exe'  => 'application/octet-stream',
    '.gif'  => 'image/gif',
    '.jpg'  => 'image/jpeg',
    '.pdf'  => 'application/pdf',
    '.png'  => 'image/png',
    '.oga'  => 'audio/ogg',
    '.ogg'  => 'audio/ogg',
    '.ogv'  => 'video/ogg',
    '.mov'  => 'video/quicktime',
    '.mp3'  => 'audio/mpeg',
    '.mp4'  => 'video/mp4',
    '.spx'  => 'audio/speex',
    '.txt'  => 'text/plain',
    '.text' => 'text/plain',
    '.wav'  => 'audio/x-wav',
    '.zip'  => 'application/zip'
  } unless defined? FILE_TYPES

  DISPOSITION = {
    'application/octet-stream' => 'attachment',
    'application/pdf'          => 'inline',
    'image/gif'                => 'inline',
    'image/jpeg'               => 'inline',
    'image/png'                => 'inline',
    'audio/mpeg'               => 'inline',
    'audio/x-wav'              => 'inline',
    'audio/x-aiff'             => 'inline',
    'audio/speex'              => 'inline',
    'audio/ogg'                => 'inline',
    'video/ogg'                => 'inline',
    'video/mp4'                => 'inline',
    'video/quicktime'          => 'inline',
    'video/x-msvideo'          => 'inline',
    'text/plain'               => 'inline',
    'application/zip'          => 'attachment'
  } unless defined? DISPOSITION

  def self.wiki
    Wiki.new
  end

  protected

    def darken(s)
       n=s.length/3
       s.scan( %r(\w{#{n},#{n}}) ).collect {|a| (a.hex * 2/3).to_s(16).rjust(n,'0')}.join
    end

    def check_authorization
      if in_a_web? and authorization_needed? and not authorized?
        redirect_to :controller => 'wiki', :action => 'login', :web => @web_name
        return false
      end
    end

    def connect_to_model
      @action_name = params['action'] || 'index'
      @web_name = params['web']
      @wiki = wiki
      @author = cookies['author'] || 'AnonymousCoward'
      if @web_name
        @web = @wiki.webs[@web_name]
        if @web.nil?
          render plain: "Unknown web '#{@web_name}'", status: 404
          return false
        end
      end
    end

    def determine_file_options_for(file_name, original_options = {})
      original_options[:type] ||= (FILE_TYPES[File.extname(file_name)] or 'application/octet-stream')
      original_options[:disposition] ||= (DISPOSITION[original_options[:type]] or 'attachment')
      original_options[:stream] ||= false
      original_options[:x_sendfile] = true if request.env.include?('HTTP_X_SENDFILE_TYPE') &&
              ( request.remote_addr == LOCALHOST || defined?(PhusionPassenger) )
      original_options
    end

    def send_file(file, options = {})
      determine_file_options_for(file, options)
      super(file, options)
    end

    def password_check(password)
      if password == @web.password
        cookies[CGI.escape(@web_name)] = password
        true
      else
        false
      end
    end

    def password_error(password)
      if password.nil? or password.empty?
        'Please enter the password.'
      else
        'You entered a wrong password. Please enter the right one.'
      end
    end

    def redirect_home(web = @web_name)
      if web
        redirect_to_page('HomePage', web)
      else
        redirect_to '/'
      end
    end

    def redirect_to_page(page_name = @page_name, web = @web_name)
      redirect_to :web => web, :controller => 'wiki', :action => 'show',
          :id => (page_name or 'HomePage')
    end

    def remember_location
      if request.method == :get and
          @status == '200' and not \
          %w(locked save back file pic import).include?(action_name)
        session[:return_to] = request.request_uri
        Rails.logger.debug "Session ##{session.object_id}: remembered URL '#{session[:return_to]}'"
      end
    end

    def rescue_action_in_public(exception)
        render :status => 500, :text => <<-EOL
          <html xmlns="http://www.w3.org/1999/xhtml"><body>
            <h2>Internal Error</h2>
            <p>An application error occurred while processing your request.</p>
            <!-- \n#{exception.to_s.gsub!(/-{2,}/, '- -') }\n#{exception.backtrace.join("\n")}\n -->
          </body></html>
        EOL
    end

    def return_to_last_remembered
      # Forget the redirect location
      redirect_target, session[:return_to] = session[:return_to], nil
      tried_home, session[:tried_home] = session[:tried_home], false

      # then try to redirect to it
      if redirect_target.nil?
        if tried_home
          raise 'Application could not render the index page'
        else
          Rails.logger.debug("Session ##{session.object_id}: no remembered redirect location, trying home")
          redirect_home
        end
      else
        Rails.logger.debug("Session ##{session.object_id}: " +
            "redirect to the last remembered URL #{redirect_target}")
        redirect_to(redirect_target)
      end
    end

    def set_content_type_header
      response.charset = 'utf-8'
      if %w(atom_with_content atom_with_headlines).include?(action_name)
        response.content_type = Mime[:atom].to_s
      else
        response.content_type = Mime[:html].to_s
      end
    end

    def set_robots_metatag
      if controller_name == 'wiki' and %w(show published).include? action_name and !(params[:mode] == 'diff')
        @robots_metatag_value = 'index,follow'
      else
        @robots_metatag_value = 'noindex,nofollow'
      end
    end

    def setup_url_generator
      PageRenderer.setup_url_generator(UrlGenerator.new(self))
    end

    def teardown_url_generator
      PageRenderer.teardown_url_generator
    end

    def wiki
      self.class.wiki
    end

  private

    def in_a_web?
      not @web_name.nil?
    end

    def authorization_needed?
      not %w(login authenticate feeds published atom_with_headlines atom_with_content file).include?(action_name)
    end

    def authorized?
      @web.nil? or
      @web.password.nil? or
      cookies[CGI.escape(@web_name)] == @web.password or
      password_check(params['password'])
    end

    def is_post
      unless (request.post? || Rails.env.test?)
        headers['Allow'] = 'POST'
        render(status: 405, text: 'You must use an HTTP POST', layout: 'error')
        return false
      end

      return true
    end

    # Used for the unusual range of ".foo" formats that might arise for a
    # family of XML-based responses; #on_error_rotate_and_raise needs to
    # know what the format in which to render an error.
    #
    XML_LIKE_MAP = {
      xml:           'application/xml',
      rss:           'application/rss+xml',
      rss20:         'application/rss+xml',
      atom:          'application/atom+xml',
      atom10:        'application/atom+xml',
      rsd:           'application/rsd+xml',
      googlesitemap: 'application/xml',
    }

    XML_LIKE_MAP.each do | format, mime |
      known_mime = Mime::Type.lookup_by_extension(format)
      Mime::Type.register(mime, format) if known_mime.blank?
    end

    XML_LIKE_FORMATS = XML_LIKE_MAP.keys.freeze

    # Renders an exception, retaining Hub login. Regenerate any exception
    # within five seconds of a previous render to 'raise' to default Rails
    # error handling, which (in non-Production modes) gives additional
    # debugging context and an inline console, but loses the Hub session
    # rotated key, so you're logged out.
    #
    def on_error_rotate_and_raise(exception)
      hubssolib_get_session_proxy()
      hubssolib_afterwards()

      if session[:last_exception_at].present?
        last_at = Time.parse(session[:last_exception_at]) rescue nil
        raise if last_at.present? && Time.now - last_at < 5.seconds
      end

      session[:last_exception_at] = Time.now.iso8601(1)
      locals                      = { exception: exception }

      # Depending on application, XML variants can be numerous - e.g. ".rss",
      # ".rss20" and so-on - so use that as a default for anything that is not
      # otherwise explicitly recognised as a JSON or HTML request.
      #
      respond_to do | format |
        format.html { render 'exception', locals: locals }
        format.json { render 'exception', locals: locals, formats: :json }

        format.any(*XML_LIKE_FORMATS) do
          render 'exception', locals: locals, formats: :xml
        end
      end
    end

end

module MathPlayerHack
    def charset=(encoding)
      self.headers["Content-Type"] = "#{content_type || Mime[:html].to_s}"
    end
end

module Instiki
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 19
    TINY  = 1
    SUFFIX = '(MML+)'
    PRERELEASE =  false
    if PRERELEASE
       STRING = [MAJOR, MINOR].join('.') + PRERELEASE + SUFFIX
    else
       STRING = [MAJOR, MINOR, TINY].join('.') + SUFFIX
    end
  end
end
