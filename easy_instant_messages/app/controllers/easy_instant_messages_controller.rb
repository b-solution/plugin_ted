class EasyInstantMessagesController < ApplicationController
  accept_api_auth :index, :show_easy_chat

  before_action :require_login

  def index
    @easy_instant_messages = EasyInstantMessage.for_user(User.current).where(:unread => true).order(:created_at)
    respond_to do |format|
      format.js {@easy_instant_messages = @easy_instant_messages.all}
      # format.xml {render :xml => @easy_instant_messages}
      # format.json {render :json => @easy_instant_messages}
      format.api
    end
  end

  def conversations
    @conversations = EasyInstantConversation.for_user(User.current)

    respond_to do |format|
      format.js
    end
  end

  def conversation
    @conversation = EasyInstantConversation.between_users(User.current, User.find(params[:id]))
    @num_of_unread_messages_before_read = @conversation.num_of_unread_messages
    @conversation.mark_read

    respond_to do |format|
      format.html
      format.js {
        @conversation.messages = @conversation.messages.last(15)
      }
    end
  end

  def show_easy_chat
    # scope = EasyInstantMessage.for_user(User.current).order(created_at: :desc)
    # if (@easy_instant_messages = scope.preload(sender: [:email_address]).where(unread: true).to_a).present?
    #   if @easy_instant_messages.map(&:sender_id).uniq.count == 1
    #     @user = @easy_instant_messages.first.sender
    #     # scope.where(unread: true).update_all(unread: false)
    #
    #     respond_to do |format|
    #       format.js do
    #         @open_new_chat = true
    #         return new
    #       end
    #     end
    #   end
    # else
    #   # TODO: Get top 5 senders
    #   easy_instant_messages = {}
    #   scope.select(:sender_id, :created_at).first(100).each do |msg|
    #     easy_instant_messages[msg.sender_id] ||= scope.where(sender_id: msg.sender_id).limit(1).pluck(:id)
    #     break if easy_instant_messages.keys.count == 5
    #   end
    #   @easy_instant_messages = EasyInstantMessage.for_user(User.current).where(id: easy_instant_messages.values.flatten).preload(sender: [:email_address]).order(created_at: :desc).to_a
    # end

    @conversations = EasyInstantConversation.for_user(User.current)

    respond_to do |format|
      format.js
    end
  end

  def contacts
    @contacts = User.active.like(params[:q]).where.not(id: User.current.id) # do not include current user himself
    @contacts = @contacts.easy_type_internal if defined?(EasyExtensions)

    respond_to do |format|
      format.js
    end
  end

  def create
    @easy_instant_message = EasyInstantMessage.new(:sender => User.current)
    @easy_instant_message.safe_attributes = params[:easy_instant_message]
    @easy_instant_message.sender_ip = request.remote_ip

    respond_to do |format|
      if @easy_instant_message.save
        format.js {@exit = {:type => 'notice', :text => l(:notice_easy_instant_message_sended)}}
      else
        format.js {@exit = {:type => 'error', :text => ''}}
      end
    end
  end

  def read
    @easy_instant_message = EasyInstantMessage.find(params[:id])

    if @easy_instant_message.update_attributes(unread: false)
      render nothing: true, status: 200
    end
  end

  def toggle_sound
    @user = User.current
    Rails.cache.delete [:easy_instant_message, :mute_messaging, @user]
    if @user.pref.others[:easy_instant_message_mute]
      @user.pref.others.delete(:easy_instant_message_mute)
    else
      @user.pref.others[:easy_instant_message_mute] = true
    end
    @user.pref.save
    respond_to do |format|
      format.js
    end
  end
end
