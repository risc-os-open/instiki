module AuthenticationSystem

  # Hub single sign-on support. The core of the old authentication system is
  # now delegated to this.

  require 'hub_sso_lib'
  include HubSsoLib::Core

  protected
    # this is used to keep track of the last time a user has been seen (reading a topic)
    # it is used to know when topics are new or old and which should have the green
    # activity light next to them
    #
    # we cheat by not calling it all the time, but rather only when a user views a topic
    # which means it isn't truly "last seen at" but it does serve it's intended purpose
    #
    # this could be a filter for the entire app and keep with it's true meaning, but that
    # would just slow things down without any forseeable benefit since we already know
    # who is online from the user/session connection
    #
    # This is now also used to show which users are online... not at accurate as the
    # session based approach, but less code and less overhead.
    def update_last_seen_at
      return unless logged_in?
      current_user.update!(last_seen_at: Time.now.utc)
    end

    def login_required
      login_by_token unless logged_in?
      respond_to do |format|
        format.html { redirect_to login_path }
        format.js   { render(:update) { |p| p.redirect_to login_path } }
        format.xml  do
          headers["WWW-Authenticate"] = %(Basic realm="Beast")
          render :text => "HTTP Basic: Access denied.\n", :status => :unauthorized
        end
      end unless logged_in? && authorized?
    end

    def login_by_token
      # Before doing anything else, check for stale login status. If logged out of
      # Hub but there's still an session active recorded internally, delete it. Do
      # the same if the e-mail address has changed (the user logged into a different
      # Hub account).

      if (logged_in?)
        if (!hubssolib_logged_in? || current_user.email != hubssolib_get_user_address)
          reset_session
          self.current_user = setup_user
          return
        end
      end

      # Don't confuse the local "logged_in?" session check with the notion
      # of being logged into Hub ("hubssolib_logged_in?").

      self.current_user = setup_user if not logged_in?
    end

    def authorized?() true end

    def current_user=(value)
      if @current_user = value
        session[:user_id] = @current_user.id
        # this is used while we're logged in to know which threads are new, etc
        session[:last_active] = @current_user.last_seen_at
        session[:topics] = session[:forums] = {}
        update_last_seen_at
      end
    end

    def current_user
      @current_user ||= ((session[:user_id] && User.find_by_id(session[:user_id])) || 0)
    end

    def logged_in?
      current_user != 0 && hubssolib_logged_in?
    end

    def admin?
      logged_in? && current_user.admin?
    end

    # Get a unique login string from the Hub user, in abstracted form.
    # While it must be unique, its content is irrelevant in the Hub
    # integrated forum as it doesn't get displayed. We use this instead
    # of e-mail address because we want to detect an e-mail address
    # being used more than once by different users to cope with stale
    # Hub accounts or recycled e-mail addresses.
    #
    def get_hub_user_name
      Digest::SHA1.hexdigest("#{hubssolib_unique_name}")
    end

    # Map a Hub user's parameters to a forum User model's
    # parameters. Returns a hash appropriate for updating an
    # existing model or to create a brand new forum User.
    #
    def map_hub_user_to_forum_user
      return(
        {
          login:        get_hub_user_name(),
          email:        hubssolib_get_user_address(),
          admin:        hub_user_is_forum_admin?,
          display_name: hubssolib_unique_name(),
          website:      '',
          bio:          '',
          bio_html:     '',
          activated:    true
        }
      )
    end

    # Is the current Hub user a forum administrator, based on
    # their Hub roles?
    #
    def hub_user_is_forum_admin?
      roles = hubssolib_get_user_roles()
      roles.include?('admin') || roles.include?('webmaster')
    end

    # Filter method that sets user parameters by mapping in the
    # currently logged in Hub user to a new or updated forum user.
    # Returns the user details. It is up to the caller to record
    # or discard those details.
    #
    def setup_user
      user = nil

      if (hubssolib_logged_in?)
        user = User.find_by_login(get_hub_user_name())

        # This for now is the quick and dirty code. We either create
        # a new user on a default map of parameters from Hub to
        # forum user, or we update the Hub parts - on each and every
        # action in forum. This is, obviously, very slow.

        if (user)
          user.assign_attributes(map_hub_user_to_forum_user())
        else

          # There is no user with the same unique ID, but there may be
          # a user with the same e-mail address - somebody might have
          # deleted and recreated their account, or a person may have
          # given up an e-mail address but it could have been claimed
          # by an entirely new user. In any event, a new ID with the
          # same e-mail address implies the old address is stale; Hub
          # insists on unique addreses. We don't want to delete that
          # user because their user name is associated with posts, so
          # instead, clear its email address.

          @other_user = User.find_by_email(hubssolib_get_user_address())

          if @other_user
            @other_user.email = ''
            @other_user.save!
          end

          # Now create the shiny new account and save it.

          user = User.new(map_hub_user_to_forum_user())
          user.save!
        end

        return user;
      else
        return nil;
      end
    end
end
