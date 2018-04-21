module EasyInstantMessages
  module UsersHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def user_profile_menu_item_easy_instant_messages
          new_easy_instant_message_path(:user_id => @user, :hide_modal => '1')
          #"javascript:EASY.modalSelector.closeModal();$.get('#{j new_easy_instant_message_path(:user_id => @user, :format => 'js')}')};return false;"
        end

      end
    end

    module InstanceMethods

    end
  end
end
RedmineExtensions::PatchManager.register_helper_patch 'UsersHelper', 'EasyInstantMessages::UsersHelperPatch'
