class DeleteOrphans < ActiveRecord::Migration
  def up
    # Delete messages where sender is dead
    User.reset_column_information
    EasyInstantMessage.includes(:sender).where(:users => {:id => nil}).destroy_all
  end

  def down
  end
end
