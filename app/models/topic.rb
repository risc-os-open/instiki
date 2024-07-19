class Topic < ApplicationRecord
  belongs_to :forum, counter_cache: true
  belongs_to :user
  has_many :monitorships
  has_many(
    :monitors,
    -> { where(active: true).order('users.display_name ASC') },
    through: :monitorships
  )

  # was has_many ... do
  #   def last
  #     @last_post ||= find(:first, :order => 'posts.created_at desc')
  #   end
  # end
  #
  has_many(
    :posts,
    -> { order('posts.created_at ASC') },
    dependent: :destroy
  )

  belongs_to(
    :replied_by_user,
    optional:    true,
    foreign_key: 'replied_by',
    class_name:  'User'
  )

  validates_presence_of :forum, :user, :title
  validate :title_cannot_contain_blacklisted_strings

  before_create :set_default_replied_at_and_sticky
  after_save    :set_post_topic_id

  def voices
    self.posts.distinct.select(:user_id).count
  end

  def hit!
    self.class.increment_counter(:hits, self.id)
  end

  def sticky?
    self.sticky == 1
  end

  def views
    self.hits
  end

  def editable_by?(user)
    user.present? && (user.id == self.user_id || user.admin? || user.moderator_of?(self.forum_id))
  end

  protected

    def set_default_replied_at_and_sticky
      self.replied_at = Time.now.utc
      self.sticky   ||= 0
    end

    def set_post_topic_id
      Post.where(topic_id: id).update!(forum_id: forum_id)
    end

    def title_cannot_contain_blacklisted_strings
      downcase_title = title&.downcase             || ''
      blacklist      = Blacklist.first&.title_list || ''
      prohibited     = false

      blacklist.split("\n").each do |item|
        if downcase_title.include?(item)
          prohibited = true
          break
        end
      end

      errors.add(:title, 'contains prohibited text') if prohibited == true
    end
end
