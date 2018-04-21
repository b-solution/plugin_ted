module Acl
  module Helpers
    module ExtendHelper
      def rmp_html_title(*args)
        if args.empty?
          title = @rmp_html_title || []
          title.reject(&:blank?).join(' - ')
        else
          @rmp_html_title ||= []
          @rmp_html_title += args
        end
      end

      def rmp_mailer_header(header=nil)
        if header.present?
          @rmp_mailer_header = "<div style=\"color:#000;font-weight:bold;font-family: 'Arial', serif; font-size: 17px;margin-bottom:5px;\">#{header}</div>".html_safe
        end
        (@rmp_mailer_header || '').html_safe
      end

      def calendar_for_time(field_id)
        if Setting.plugin_a_common_libs['enable_periodpicker']
          javascript_tag("$(function() {
                  $('##{field_id}').periodpicker(datetimepickerOptions);
              });")
        end
      end

      def options_for_button_css(css_class)
        css_classes = [''] # add predefined
        css_classes << css_class unless css_class.nil? || css_class == ''
        options = ''
        css_classes.sort.each do |css|
          css_name = css.split(/lb_btn_|acl_icon_/)
          css_name = (css_name.size == 2) ? css_name[1] : css_name[0]
          selected = (css == css_class) ? ' selected' : ''
          options << "<option value=\"#{css}\"#{selected}>#{css_name}</option>"
        end
        options.html_safe
      end
    end
  end
end

ActionView::Base.send(:include, Acl::Helpers::ExtendHelper)

# require 'application_controller' unless defined?(ApplicationController)
unless ApplicationController.included_modules.include?(Acl::Helpers::ExtendHelper)
  ApplicationController.send(:include, Acl::Helpers::ExtendHelper)
end