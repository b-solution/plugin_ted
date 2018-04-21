class AddIndexRecipientIdUnread < ActiveRecord::Migration
  def up
    add_index :easy_instant_messages, [:recipient_id, :unread]
  end

  def down
  end
end