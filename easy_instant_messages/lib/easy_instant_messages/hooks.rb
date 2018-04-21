module EasyInstantMessages
  class Hooks < Redmine::Hook::ViewListener

    def view_layouts_base_body_bottom(context={})
      return unless User.current.logged?
      if context[:controller].request.format.html?
          context[:controller].send(:render_to_string, partial: 'easy_instant_messages/render_easy_instant_messages_box', locals: context)
      end
    end

    # def view_layout_before_quick_search(context={})
      # return unless User.current.logged?
      # format = context[:controller].params[:format]
      # if (format.nil? || format == 'html') && !context[:controller].in_mobile_view?
       # contacts_easy_instant_messages_path
        #link_to('', read_easy_instant_messages_path, :class => 'icon-comments', :title => l(:label_easy_instant_messages), :id => :easy_instant_messages_list_trigger, :method => :post, :remote => true) unless User.current.in_mobile_view?
      # end
    # end

    # def view_layouts_base_body_bottom(context={})
      # if User.current.logged? && !context[:controller].in_mobile_view?
      #   format = context[:controller].params[:format]
      #   if format.nil? || format == 'html'

      #     context[:controller].send(:render_to_string, :partial => 'easy_instant_messages/easy_instant_messages_tooltip_container', :locals => context)
      #   end
      # end
    # end
  end
end
