Redmine::Plugin.register :easy_instant_messages do
  if Redmine::Plugin.installed?(:easy_extensions)
    name :easy_instant_messages_plugin_name
    description :easy_instant_messages_plugin_description
  else
    name 'Project chat'
    description 'Sending instant messages'
  end

  author 'Easy Software Ltd'
  author_url 'www.easysoftware.cz'
  version '2016'
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end

