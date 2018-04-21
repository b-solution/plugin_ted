class CreateEasyInstantMessages < ActiveRecord::Migration
  def up
    create_table :easy_instant_messages, :force => true do |t|
      t.references :sender
      t.references :recipient

      t.text :content

      t.string :sender_ip

      t.timestamps
    end

    add_index :easy_instant_messages, [:sender_id, :recipient_id]
    add_index :easy_instant_messages, [:recipient_id, :sender_id]
  end

  def down
    drop_table :easy_instant_messages
  end
end
