module EasyInstantMessagesHelper
  include EasyAttendancesHelper if defined?(EasyAttendancesHelper)

  def easy_instant_messages_avatar_url(user = nil)
    if defined? avatar_url
      avatar_url(user)
    else
      user ||= User.current
      result = if Setting.gravatar_enabled?
                 options = {:ssl => (request && request.ssl?), :default => Setting.gravatar_default}
                 email = nil
                 if user.respond_to?(:mail)
                   email = user.mail
                 elsif user.to_s =~ %r{<(.+?)>}
                   email = $1
                 end
                 gravatar_url(email, options)
               elsif user.respond_to?(:easy_avatar) && (av = user.easy_avatar).present? && (img_url = av.image.url(:small))
                 get_easy_absolute_uri_for(img_url).to_s
               end
      result
    end
  end

  def easy_logo
    image_tag 'easy-logo.svg', plugin: :easy_instant_messages
  end

  def back_arrow
    image_tag 'back-arrow.svg', plugin: :easy_instant_messages
  end
end
