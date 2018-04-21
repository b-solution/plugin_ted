class EasyInstantMessage < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  validates :content, :recipient_id, presence: true
  validate :cant_send_message_to_self

  attr_protected :id

  scope :for_user, lambda { |user = User.current| where(recipient_id: user) }
  scope :all_for_user, lambda { |user = User.current| joins(:sender, :recipient).where(users: {status: User::STATUS_ACTIVE}, recipients_easy_instant_messages: {status: User::STATUS_ACTIVE}).where("#{EasyInstantMessage.table_name}.sender_id = :u OR #{EasyInstantMessage.table_name}.recipient_id = :u", {u: user.id}) }

  safe_attributes 'recipient_id', 'content'

  if Redmine::Plugin.installed?(:easy_extensions)
    html_fragment :content, scrub: :strip
  end

  before_create :strip_content

  def self.is_muted?
    Rails.cache.fetch [:easy_instant_message, :mute_messaging, User.current] do
      !User.current.pref.others[:easy_instant_message_mute].nil?
    end
  end

  def strip_content
    self.content.strip!
  end

  def cant_send_message_to_self
    errors[:base] << l(:error_easy_instant_messages_send_message_to_self) if sender_id == recipient_id
  end

  def notified_users
    [recipient]
  end

end
