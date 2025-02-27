#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Projects::Schemas::ProjectSchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { FactoryBot.build_stubbed(:user) }

  let(:self_link) { '/a/self/link' }
  let(:embedded) { true }
  let(:new_record) { true }
  let(:custom_field) do
    FactoryBot.build_stubbed(:int_project_custom_field)
  end
  let(:allowed_status) { ['some status'] }
  let(:contract) do
    contract = double('contract')

    allow(contract)
      .to receive(:writable?) do |attribute|
      writable = %w(name identifier description is_public status)

      writable.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:available_custom_fields)
      .and_return([custom_field])

    allow(contract)
      .to receive(:assignable_values)
      .with(:status, current_user)
      .and_return(allowed_status)

    contract
  end
  let(:representer) do
    described_class.create(contract,
                           self_link,
                           form_embedded: embedded,
                           current_user: current_user)
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    describe '_type' do
      it 'is indicated as Schema' do
        is_expected.to be_json_eql('Schema'.to_json).at_path('_type')
      end
    end

    describe 'id' do
      let(:path) { 'id' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'Integer' }
        let(:name) { I18n.t('attributes.id') }
        let(:required) { true }
        let(:writable) { false }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'name' do
      let(:path) { 'name' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'String' }
        let(:name) { I18n.t('attributes.name') }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'indicates length requirements' do
        let(:min_length) { 1 }
        let(:max_length) { 255 }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'identifier' do
      let(:path) { 'identifier' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'String' }
        let(:name) { I18n.t('activerecord.attributes.project.identifier') }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'indicates length requirements' do
        let(:min_length) { 1 }
        let(:max_length) { 100 }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'description' do
      let(:path) { 'description' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'Formattable' }
        let(:name) { I18n.t('attributes.description') }
        let(:required) { false }
        let(:writable) { true }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'public' do
      let(:path) { 'public' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'Boolean' }
        let(:name) { I18n.t('attributes.is_public') }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'status' do
      let(:path) { 'status' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'String' }
        let(:name) { I18n.t('attributes.status') }
        let(:required) { true }
        let(:writable) { true }
      end

      it 'contains no link to the allowed values' do
        is_expected
          .not_to have_json_path("#{path}/_links/allowedValues")
      end

      it 'embeds the allowed values' do
        allowed_path = "#{path}/_embedded/allowedValues"

        is_expected
          .to be_json_eql(allowed_status.to_json)
          .at_path(allowed_path)
      end
    end

    describe 'createdAt' do
      let(:path) { 'createdAt' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'DateTime' }
        let(:name) { I18n.t('attributes.created_at') }
        let(:required) { true }
        let(:writable) { false }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'updatedAt' do
      let(:path) { 'updatedAt' }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'DateTime' }
        let(:name) { I18n.t('attributes.updated_at') }
        let(:required) { true }
        let(:writable) { false }
      end

      it_behaves_like 'has no visibility property'
    end

    describe 'int custom field' do
      let(:path) { "customField#{custom_field.id}" }

      it_behaves_like 'has basic schema properties' do
        let(:type) { 'Integer' }
        let(:name) { custom_field.name }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    context '_links' do
      describe 'self link' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'self' }
          let(:href) { self_link }
        end

        context 'embedded in a form' do
          let(:self_link) { nil }

          it_behaves_like 'has no link' do
            let(:link) { 'self' }
          end
        end
      end
    end
  end
end
