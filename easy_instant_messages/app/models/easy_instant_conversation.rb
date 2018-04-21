class EasyInstantConversation < Struct.new(:secondparty, :messages)
  class << self
    def for_user(user)
      messages = ActiveSupport::OrderedHash.new {|hsh, key| hsh[key] = []}; batch_size = 25
      ids = EasyInstantMessage.all_for_user(user).order(created_at: :desc).ids
      ids.each_slice(batch_size) do |chunk|
        EasyInstantMessage.where(id: chunk).order(created_at: :desc).preload(:recipient).each do |im|
          messages[im.sender_id] << im
          break if messages.keys.size == 10
        end
        break if messages.keys.size == 10 || messages.values.size == (batch_size * 2)
      end

      User.where(id: (messages.keys - [user.id])).preload(:email_address).collect do |user|
        EasyInstantConversation.new(user, messages[user.id].sort_by(&:created_at))
      end.sort { |a, b| b.last_message <=> a.last_message }
    end

    def between_users(firstparty, secondparty)
      firstparty_id = firstparty.id
      secondparty_id = secondparty.id

      # messages = EasyInstantMessage.where("(sender_id = ? AND recipient_id =?) OR (recipient_id = ? AND sender_id = ?)", firstparty_id, secondparty_id, firstparty_id, secondparty_id).order('created_at ASC').preload(:sender).last(15)
      messages = EasyInstantMessage.where("(sender_id = ? AND recipient_id =?) OR (recipient_id = ? AND sender_id = ?)", firstparty_id, secondparty_id, firstparty_id, secondparty_id).order('created_at ASC').preload(:sender)

      new(secondparty, messages)
    end

    private

    # sorts conversations by their last message's creation time
    def sort_groups(groups)
      groups.sort_by { |_, messages| messages.last.created_at }.reverse
    end
  end

  def last_message
    @last_message ||= messages.last
  end

  def unread_messages
    messages.select { |m| m.sender_id == secondparty.id && m.unread }
  end

  def num_of_unread_messages
    unread_messages.size
  end

  def mark_read
    EasyInstantMessage.where(id: unread_messages.map(&:id)).update_all(unread: false)
  end

  def to_partial_path
    'conversation'
  end
end
