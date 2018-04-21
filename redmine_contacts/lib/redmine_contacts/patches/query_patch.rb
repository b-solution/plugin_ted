# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2017 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require_dependency 'query'

module RedmineContacts
  module Patches
    module QueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :add_filter, :contacts
          alias_method_chain :available_filters_as_json, :contacts
        end
      end

      module InstanceMethods
        def add_filter_with_contacts(field, operator, values=nil)
          add_filter_without_contacts(field, operator, values)

          if available_filters[field] && %w(company contact).include?(available_filters[field][:field_format])
            filter_options = available_filters[field]
            # Method :contact_query_values should be defined in query class for model
            filter_options[:values] = contact_query_values(values) if respond_to?(:contact_query_values)
            return if filter_options[:values].present?
            filter_options[:values] = Contact.joins(:projects).where(Contact.visible_condition(User.current)).
                                             where(:id => values).
                                             to_a.sort!{|x, y| x.name <=> y.name }.
                                             collect {|m| [m.name, m.id.to_s]}
          end
          return true
        end

        def available_filters_as_json_with_contacts()
          json_data = available_filters_as_json_without_contacts
          Hash[json_data.map do |f_name, f_data|
            f_data['field_format'] = available_filters[f_name][:field_format]
            [f_name, f_data]
          end]
        end
      end
    end
  end
end

unless Query.included_modules.include?(RedmineContacts::Patches::QueryPatch)
  Query.send(:include, RedmineContacts::Patches::QueryPatch)
end
