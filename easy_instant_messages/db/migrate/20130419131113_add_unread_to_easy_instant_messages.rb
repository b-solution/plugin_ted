# encoding: utf-8
class AddUnreadToEasyInstantMessages < ActiveRecord::Migration
  def change
    add_column :easy_instant_messages, :unread, :boolean, {:default => true}
  end
end
