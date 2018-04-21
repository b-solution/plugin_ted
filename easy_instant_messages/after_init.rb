Dir[File.dirname(__FILE__) + '/lib/easy_instant_messages/redmine/**/*.rb'].each {|file| require_dependency file }

ActiveSupport.on_load(:easyproject, yield: true) do

  if Redmine::Plugin.installed?(:easy_extensions)

    Rails.application.configure do
      assets_dir = Redmine::Plugin.find(:easy_instant_messages).assets_directory
      config.assets.paths << File.join(assets_dir, 'audios')
      config.assets.precompile << File.join(assets_dir, 'audios', 'chat1.mp4')
      config.assets.precompile << File.join(assets_dir, 'stylesheets', 'easy_instant_messages_easy.css')
    end

    Redmine::MenuManager.map :easy_servicebar_items do |menu|
      menu.push(:easy_instant_messages_list_trigger, :conversations_easy_instant_messages_path, :html => {
        :class => 'icon-comments',
        :id => 'easy_instant_messages_toggle',
        :title => EasyExtensions::MenuManagerProc.new {I18n.t(:label_easy_instant_messages)},
        :remote => true
      }, :caption => '',
        :if => lambda{|_project| User.current.allowed_to_globally?(:use_easy_instant_messages, {})}
      )
    end
    Redmine::AccessControl.map do |map|
      map.easy_category(:easy_instant_messages) do |pmap|
        pmap.permission(:use_easy_instant_messages, {easy_instant_messages: [:index]}, :global => true)
      end
    end

  else
    Redmine::AccessControl.map do |map|
        map.permission(:use_easy_instant_messages, {easy_instant_messages: [:index]}, :global => true)
    end
  end

  require 'easy_instant_messages/hooks'
end
