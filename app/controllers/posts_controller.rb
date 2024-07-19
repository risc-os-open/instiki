class PostsController < ApplicationController
  before_action :find_post, except: [:index, :index_rss, :create, :monitored, :search]

  HUBSSOLIB_PERMISSIONS = HubSsoLib::Permissions.new(
    {
      :new     => [ :admin, :webmaster, :privileged, :normal ],
      :create  => [ :admin, :webmaster, :privileged, :normal ],
      :edit    => [ :admin, :webmaster, :privileged, :normal ],
      :update  => [ :admin, :webmaster, :privileged, :normal ],
      :destroy => [ :admin, :webmaster ],
    }
  )

  def self.hubssolib_permissions
    HUBSSOLIB_PERMISSIONS
  end

  # @@query_options = {
  #   :select => 'posts.*, topics.title as topic_title, forums.name as forum_name',
  #   :joins => 'inner join topics on posts.topic_id = topics.id inner join forums on topics.forum_id = forums.id',
  #   :order => 'posts.created_at desc'
  # }

  def index
    index_initialise
    render_posts_or_xml
  end

  # Backwards compatibility with RForum global feed via a routing hack.
  #
  def index_rss
    index_initialise
    render action: 'index.xml.erb', layout: false
  end

  def search
    # conditions = params[:q].blank? ? nil : Post.send(:sanitize_sql, ['LOWER(posts.body) LIKE ?', "%#{params[:q].downcase}%"])
    # @post_pages, @posts = paginate(:posts, @@query_options.merge(:conditions => conditions).merge(per_page()))
    #
    safe_q = ActiveRecord::Base.sanitize_sql_like(params[:q]) if params[:q].present?
    scope  = Post.joins(:topic, :forum).order(created_at: :desc)
    scope  = scope.where('LOWER(posts.body) LIKE ?', "%#{safe_q.downcase}%") if safe_q.present?

    @pagy, @posts = pagy(scope)

    # @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:user_id).uniq]).index_by(&:id)
    #
    @users = User.distinct.where(id: @posts.pluck(:user_id)).index_by(&:id)

    render_posts_or_xml :index
  end

  def monitored
    @user = User.find(params[:user_id])

    # options = @@query_options.merge(:conditions => ['monitorships.user_id = ? and posts.user_id != ?', params[:user_id], @user.id])
    # options[:joins] += ' inner join monitorships on monitorships.topic_id = topics.id'
    # @post_pages, @posts = paginate(:posts, options.merge(per_page()))
    #
    scope = Post
      .joins(:forum, :topic => :monitorships)
      .order(created_at: :desc)
      .where(user_id: @user.id, topic: { monitorships: { user_id: @user.id } })

    @pagy, @posts = pagy(scope)

    render_posts_or_xml
  end

  def show
    respond_to do |format|
      format.html { redirect_to forum_topic_path(forum_id: @post.forum_id, id: @post.topic_id) }
      format.xml  { render(xml: @post.to_xml) }
    end
  end

  def create
    @topic = Topic.find_by_id_and_forum_id(params[:topic_id], params[:forum_id])

    if @topic.locked?
      respond_to do |format|
        format.html do
          redirect_to(long_topic_path(), notice: 'This topic is locked.')
        end

        format.xml do
          render(text: 'This topic is locked.', status: 400)
        end
      end

      return # NOTE EARLY EXIT
    end

    @forum = @topic.forum
    @post  = @topic.posts.build(self.post_params())
    @post.user = current_user
    @post.save!

    respond_to do |format|
      format.html do
        redirect_to(long_topic_path(@post.dom_id))
      end

      format.xml do
        head(
          :created,
          location: post_url(id: @post.id, forum_id: params[:forum_id], topic_id: params[:topic_id], format: :xml)
        )
      end
    end

  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'Your reply was empty, or contained prohibited words'

    respond_to do |format|
      format.html do
        redirect_to(long_topic_path('reply-form'))
      end

      format.xml do
        render(xml: @post.errors.to_xml, status: 400)
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @post.update!(post_params())

  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'Your edited post was empty, or contained prohibited words'

  ensure
    respond_to do |format|
      format.html do
        redirect_to(long_topic_path(@post.dom_id))
      end

      format.js
      format.xml { head(200) }
    end
  end

  def destroy
    @post.destroy
    flash[:notice] = "Post of '#{CGI::escapeHTML @post.topic.title}' was deleted."

    # Check for posts_count == 1 because its cached and counting the currently
    # deleted post.
    #
    if @post.topic.posts_count == 1
      @post.topic.destroy!
      redirect_to forum_path(params[:forum_id])
    else
      respond_to do |format|
        format.html do
          redirect_to(long_topic_path())
        end

        format.xml do
          head(200)
        end
      end
    end
  end

  protected

    def post_params
      params.require(:post).permit(:body)
    end

    def index_initialise
      # conditions = []
      # [:user_id, :forum_id].each { |attr| conditions << Post.send(:sanitize_sql, ["posts.#{attr} = ?", params[attr]]) if params[attr] }
      # conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
      #
      scope          = Post.all
      scope_adjusted = false

      [:user_id, :forum_id].each do |attr|
        if params[attr].present?
          scope          = scope.where(attr => params[attr])
          scope_adjusted = true
        end
      end

      if scope_adjusted == false
        if params[:tests_and_aldershot] == 'yes'
          scope = scope.joins(:forum).where(forum: {name: ['Aldershot', 'Tests']})
        elsif params[:everything] != 'yes'
          scope = scope.joins(:forum).where.not(forum: {name: ['Aldershot', 'Tests']})
        end
      end

      @pagy, @posts = pagy(scope)

      # @users = User.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:user_id).uniq]).index_by(&:id)
      #
      @users = User.distinct.where(id: @posts.pluck(:user_id)).index_by(&:id)
    end

    def authorized?
      action_name == 'create' || @post.editable_by?(current_user)
    end

    def find_post
      scope = Post.where(
        id:       params[:id],
        topic_id: params[:topic_id],
        forum_id: params[:forum_id]
      )

      @post = scope.first || raise(ActiveRecord::RecordNotFound)
    end

    def render_posts_or_xml(template_name = action_name)
      respond_to do |format|
        format.html { render action: template_name }
        format.rss  { render action: "#{template_name}.xml.erb", layout: false }
        format.xml  { render xml: @posts.to_xml }
      end
    end

    def long_topic_path(anchor = nil)
      options = {
        forum_id: params[:forum_id],
        id:       params[:topic_id]
      }

      options[:anchor] = anchor unless (anchor.nil?)
      options[:page  ] = (params[:page ] ||                   '1').to_i.to_s if (params.key?(:page ))
      options[:items ] = (params[:items] || Pagy::DEFAULT[:items]).to_i.to_s if (params.key?(:items))

      forum_topic_path(options)
    end
end
