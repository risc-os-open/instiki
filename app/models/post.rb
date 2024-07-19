class Post < ApplicationRecord
  include WhiteListFormattedContentConcern

  belongs_to :forum, counter_cache: true
  belongs_to :user,  counter_cache: true
  belongs_to :topic, counter_cache: true

  format_attribute :body

  before_validation do | post |
    post.forum = post.topic.forum
  end

  after_create do | post |
    topic = Topic.find(post.topic_id)
    topic.update!(
      replied_at:   post.created_at,
      replied_by:   post.user_id,
      last_post_id: post.id
    )
  end

  after_destroy do | post |
    topic     = Topic.find(post.topic_id)
    last_post = topic.posts.last

    if last_post.present?
      topic.update!(
        replied_at:   last_post.created_at,
        replied_by:   last_post.user_id,
        last_post_id: last_post.id
      )
    end
  end

  validates_presence_of :user_id, :body
  validate :body_cannot_contain_blacklisted_strings

  def editable_by?(user)
    user && (user.id == user_id || user.admin? || user.moderator_of?(topic.forum_id))
  end

  def to_xml(options = {})
    options[:except] ||= []
    options[:except] << :topic_title << :forum_name
    super
  end

  def body_cannot_contain_blacklisted_strings
    downcase_body = body&.downcase        || ''
    blacklist     = Blacklist.first&.list || ''
    prohibited    = false

    blacklist.split("\n").each do |item|
      if downcase_body.include?(item)
        prohibited = true
        break
      end
    end

    errors.add(:body, 'contains prohibited text') if prohibited == true
  end
end
