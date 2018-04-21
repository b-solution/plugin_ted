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

module Redmine
  module FieldFormat

    class CompanyFormat < RecordList

        add 'company'
        self.customized_class_names = nil
        self.multiple_supported = false

        def label
          "label_crm_company"
        end

        def target_class
          @target_class ||= Contact
        end

        def edit_tag(view, tag_id, tag_name, custom_value, options={})
          contact = Contact.where(:id => custom_value.value).first unless custom_value.value.blank?
          view.select_contact_tag(tag_name, contact, options.merge(:id => tag_id,
                                                                   :is_company => true,
                                                                   :add_contact => true,
                                                                   :include_blank => !custom_value.custom_field.is_required))
        end

        def cast_single_value(custom_field, value, customized = nil)
          Contact.where(:id => value).first unless value.blank?
        end

        def query_filter_options(custom_field, query)
          super.merge({:field_format => 'company'})
        end
        def possible_values_options(custom_field, object = nil)
          []
        end
    end

  end
end

Redmine::FieldFormat.add 'company', Redmine::FieldFormat::CompanyFormat
