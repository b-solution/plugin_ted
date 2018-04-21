if Redmine::Plugin.installed?(:easy_instant_messages)
  resources :easy_instant_messages do
    collection do
      get :contacts
      get :freetext_users
      put :toggle_sound
      put :toggle_hidden_user_id
      get :chat, to: 'easy_instant_messages#show_easy_chat'

      get :conversations
      get :contacts
      put :read
      # delete :destroy_all
    end
    member do
      get :reply_to
      get :history
      get :conversation
    end
  end
end