# Copyright (c) 2016-2024, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'digest'

#
module Buhos
  # Module to create a blank, but usable schema for Buhos
  # Used a on installer and to create clean schemas for testing
  #
  # **Example:**
  #
  #   db=Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false)
  #   Buhos::SchemaCreation.create_db_from_scratch(db)
  #
  # db should have a correct and usable version of Buhos.
  module SchemaCreation
    VIEWS_BN=["sr_###_references_between_cd_rtr_n",
              "sr_###_resolutions_full_text",
              "sr_###_resolutions_references",
              "sr_###_resolutions_sta",
              "sr_###_references_between_cd_n",
              "sr_###_references_between_cd",
              "sr_###_bib_references",
              "sr_###_cd_id"]

    BIBLIOGRAPHICAL_DATABASES=["scopus", "wos", "scielo", "ebscohost", "refworks", "ieee", "generic", "pubmed", "lilacs", "proquest",
     "bvs"]

    # Create a usable db to work on Buhos
    # @param db_url a [String] with a connection that Sequel.connect understand, or a Sequel::Database
    # @param language used to assign default language for users
    # @param logger A Logger object could be attached to database.
    def self.create_db_from_scratch(db_url, language='en',logger=nil)
      require 'sequel'
      if db_url.is_a? Sequel::Database
        db=db_url
      else
        db=Sequel.connect(db_url, :encoding => 'utf8',:reconnect=>true)
      end
      db.logger=logger if logger
      Buhos::SchemaCreation.create_schema(db)
      Sequel.extension :migration
      Sequel::Migrator.run(db, "db/migrations")
      Buhos::SchemaCreation.create_bootstrap_data(db,language)
      Buhos::SchemaCreation.delete_views(db,language)
      db
    end

    # Create basis schema to run Buhos.
    # Updates to database are stored on /db/migrations, so don't forget later to run migrations.
    # @see {self.create_db_from_scratch}
    def self.create_schema(db)
      # Sequel try to create an already created table even in table exists

      begin
        db.create_table? :roles do
          String :id, :size => 50, :primary_key => true
          String :description
        end

        db.create_table? :users do
          primary_key :id
          String :login, :size => 255, :null => false
          String :name, :size => 255
          String :password, :size => 255, :null => false
          foreign_key :role_id, :roles, :type => String, :size => 50, :null => false, :key => [:id]
          TrueClass :active, :default=>true, :null=>false
        end


        db.create_table? :groups do
          primary_key :id
          foreign_key :group_administrator, :users, :null => false, :key => [:id]
          String :description, :text => true
          String :name, :size => 255, :null => false
        end

        db.create_join_table?(:user_id => :users, :group_id=> :groups)


        db.create_table? :systematic_reviews do
          primary_key :id
          String :name, :size => 255
          Date :date_creation
          String :description, :text => true
          String :objectives, :text => true
          Integer :year_start
          Integer :year_end
          String :keywords, :text =>true
          foreign_key :group_id, :groups, :null => false, :key => [:id]
          foreign_key :sr_administrator, :users, :key => [:id]
          TrueClass :active, :default => true, :null => false
          String :stage, :default => "search", :size => 32, :null => false

          index [:sr_administrator], :name => :sr_administrator_index
          index [:group_id], :name => :group_id_i
        end

        # Systematic review taxonomies

        db.create_table? :sr_taxonomies do
          primary_key :id
          String :name # Should be included on locale later
          String :description, :text=>true # Should be included on locale later
        end

        db.create_table? :sr_taxonomy_categories do
          primary_key :id
          foreign_key :srt_id, :sr_taxonomies, :null => false, :key => [:id]
          String :name, :size=>50 # Should be included on locale later
          String :description # Should be included on locale later
          index [:name]
        end


        db.create_table? :systematic_review_srtcs do
          foreign_key :srtc_id, :sr_taxonomy_categories, :null => false, :key => [:id]
          foreign_key :sr_id, :systematic_reviews, :null => false, :key => [:id]
          primary_key [:srtc_id, :sr_id]
        end



        db.create_table? :bibliographic_databases do
          primary_key :id
          String :name, :size => 255
          String :description, :text => true
        end


        db.create_table? :canonical_documents do
          primary_key :id
          String :type, :size => 255
          String :title, :text => true
          String :author, :text => true
          String :date, :size => 255
          String :journal, :text => true
          String :volume, :size => 255
          String :number, :size => 255
          String :pages, :size => 255
          String :book_name, :text => true
          String :editors, :text => true
          String :proceedings, :text => true
          String :place, :size => 255
          String :editorial, :size => 255
          String :doi, :size => 255
          String :pubmed, :size => 255
          Integer :year, :null => false
          String :journal_abbr, :size => 255
          longtext :abstract
          Integer :duplicated
          String :url, :text => true
          String :wos_id, :size => 32
          String :scopus_id, :size => 255
          String :ebscohost_id, :size => 255
          String :scielo_id, :size => 255
          String :refworks_id, :size => 255
        end

        db.create_table? :canonical_authors do
          primary_key :id
          String :surname, :size => 255
          String :family_name, :size => 255
          String :email, :size => 255
          String :scopus_id, :size => 255
          String :wos_id, :size => 255
        end

        db.create_table? :canonical_document_authors do
          foreign_key :canonical_document_id, :canonical_documents, :null => false, :key => [:id]
          foreign_key :canonical_author_id, :canonical_authors, :null => false, :key => [:id]
          String :affiliation, :size => 255
          String :email, :size => 255
          index [:canonical_author_id], :name => :canonical_author_id_index
          primary_key [:canonical_document_id, :canonical_author_id]
        end

        db.create_table? :searches do
          primary_key :id
          foreign_key :systematic_review_id, :systematic_reviews, :null => false, :key => [:id]
          foreign_key :bibliographic_database_id, :bibliographic_databases, :null => false, :key => [:id]
          Date :date_creation
          String :search_criteria, :text => true
          String :description, :text => true
          File   :file_body, size: :long
          String :filetype, :size => 50
          String :filename, :size => 128

          index [:bibliographic_database_id], :name => :bibliographic_database_id_index
          index [:date_creation]
          index [:systematic_review_id]
        end

        db.create_table? :records do
          primary_key :id
          foreign_key :bibliographic_database_id , :bibliographic_databases, :null => false, :key => [:id]
          String :uid, :text => true
          String :type, :size => 255
          String :title, :text => true
          String :author, :text => true
          String :date, :size => 255
          String :journal, :text => true
          String :volume, :size => 255
          String :number, :size => 255
          String :pages, :size => 255
          String :book_name, :text => true
          String :editors, :text => true
          String :proceedings, :text => true
          String :place, :size => 255
          String :publisher, :size => 255
          String :doi, :size => 255
          String :pmid, :size => 255
          String :arxiv_id, :size => 255
          foreign_key :canonical_document_id, :canonical_documents, :key => [:id]
          String :journal_abbr, :size => 128
          Integer :year
          longtext :abstract
          String :url, :text => true

          index [:bibliographic_database_id]
          index [:canonical_document_id]
        end

        db.create_table? :bib_references do
          String :id, :primary_key => true
          String :text, :text => true
          String :doi, :size => 255
          foreign_key :canonical_document_id, :canonical_documents, :key => [:id]
          index [:canonical_document_id]
        end

        db.create_join_table?(:search_id => :searches, :record_id => :records)


        db.create_join_table?({:reference_id => {:table => :bib_references, :type => String}, :record_id => :records}, {:name=>:records_references})

        db.create_table? :authorizations do
          String :id, :size => 50, :primary_key => true
          String :description, :size => 255
        end


        db.create_table? :configurations do
          String :id, :primary_key => true
          String :value , :text => true
        end

        db.create_table? :authorizations_roles do
          foreign_key :authorization_id, :authorizations, :type => String, :size => 50, :null => false, :key => [:id]
          foreign_key :role_id, :roles, :type => String, :size => 50, :null => false, :key => [:id]

          primary_key [:authorization_id, :role_id]

          index [:role_id]
        end


        db.create_table? :crossref_queries do
          String :id, :size => 100, :primary_key => true
          String :query, :text => true
          longtext  :json
        end


        db.create_table? :crossref_dois do
          String :doi, :size => 100, :primary_key => true
          String :bibtex, :text => true
          longtext :json
        end

        db.create_table? :scopus_abstracts do
          String :id, :primary_key => true
          longtext :xml
          String :doi, :size => 255
        end

        db.create_table? :decisions do
          foreign_key :systematic_review_id, :systematic_reviews, :null => false, :key => [:id]
          foreign_key :canonical_document_id, :canonical_documents, :null => false, :key => [:id]
          foreign_key :user_id, :users, :null => false, :key => [:id]
          String :stage, :size => 32, :null => false
          String :decision, :size => 255
          String :commentary, :text => true

          primary_key [:systematic_review_id, :user_id, :canonical_document_id, :stage]

          index [:canonical_document_id]
          index [:systematic_review_id]
          index [:systematic_review_id, :user_id, :stage]
          index [:user_id]
        end
        db.create_table? :resolutions do
          foreign_key :systematic_review_id, :systematic_reviews, :null => false, :key => [:id]
          foreign_key :canonical_document_id, :canonical_documents, :null => false, :key => [:id]
          foreign_key :user_id, :users, :null => false, :key => [:id]
          String :stage, :size => 32, :null => false
          String :resolution, :size => 255
          String :commentary, :text => true

          primary_key [:systematic_review_id, :canonical_document_id, :stage]

          index [:canonical_document_id]
          index [:systematic_review_id]
          index [:systematic_review_id, :canonical_document_id]
        end
      end

    end
    def self.get_id_user_by_login(db,login)
      user=db[:users][:login=>login]
      user ? user[:id] :nil
    end
    # @!group Insert bootstrap data
    def self.create_bootstrap_data(db,language='en')
      db.transaction do
        create_roles(db)
        id_admin, id_analyst, id_guest = create_users(db, language)
        create_authorizations(db)
        allocate_authorizations_to_roles(db)
        allocate_users_to_groups(db, id_admin, id_analyst, id_guest)
        insert_bib_db_data(db)
        insert_taxonomies_data(db)
        insert_basic_scales(db)
      end
    end

    def self.delete_views(db,language='en')
      #require 'logger'
      #db.loggers << Logger.new($stdout)
        db[:systematic_reviews].each do |rev|
          rev_id=rev[:id]
            VIEWS_BN.each do  |view_n|
              table_name=view_n.gsub("###", rev_id.to_s)
              if db.table_exists?(table_name.to_sym)
                db.transaction do
                  db.drop_view(table_name.to_sym)
                end
              end
            end
        end
      end


    def self.create_users(db, language)
      id_admin = get_id_user_by_login(db, 'admin')
      id_admin ||= db[:users].insert(:login => 'admin', :name => 'Administrator', :password => ::Digest::SHA1.hexdigest('admin'), :role_id => 'administrator', :active => 1, :language => language)

      id_analyst = get_id_user_by_login(db, 'analyst')
      id_analyst ||= db[:users].insert(:login => 'analyst', :name => 'Analyst', :password => ::Digest::SHA1.hexdigest('analyst'), :role_id => 'analyst', :active => 1, :language => language)

      id_guest = get_id_user_by_login(db, 'guest')
      id_guest ||= db[:users].insert(:login => 'guest', :name => 'Guest', :password => ::Digest::SHA1.hexdigest('guest'), :role_id => 'guest', :active => 1, :language => language)
      return id_admin, id_analyst, id_guest
    end

    def self.create_roles(db)

      db[:roles].insert(:id => 'administrator', :description => 'App administrator') unless db[:roles][id:'administrator']
      db[:roles].insert(:id => 'analyst', :description => 'App analyst') unless db[:roles][id:'analyst']
      db[:roles].insert(:id => 'guest', :description => 'Guest') unless db[:roles][id:'guest']
    end

    # Insert data for taxonomies
    def self.insert_taxonomies_data(db)
      taxonomies = {
          "focus" => ["practice_or_application", "theory", "research_methods", "research_results"],
          "objectives" => ["critical", "main_themes", "integration"],
          "perspective" => ["neutral", "adoption_of_posture"],
          "coverage" => ["exhaustive", "exhaustive_with_selection", "representative", "essential"],
          "organization" => ["methodology", "conceptual", "historical"],
          "receiver" => ["academics_specialist", "academics_general", "practicians_politics", "general_public"]

      }

      taxonomies.each_pair do |category, values|
        f_id = db[:sr_taxonomies][:name=>category] && db[:sr_taxonomies][:name=>category][:id]
        f_id = db[:sr_taxonomies].insert(:name => category) unless f_id
        values.each do |name|
          db[:sr_taxonomy_categories].insert(:srt_id => f_id, :name => name) if  db[:sr_taxonomy_categories].where(:srt_id => f_id, :name => name).empty?
        end
      end
    end
    # Insert data for bibliographic databases
    def self.insert_bib_db_data(db)
      BIBLIOGRAPHICAL_DATABASES.each do |bib_db|
        bib_db_o=db[:bibliographic_databases][:name=>bib_db]
        db[:bibliographic_databases].insert(:name => bib_db) unless bib_db_o
      end
    end
    def self.insert_basic_scales(db)
      scales = {
          1=>{-99=>'not_applicable', -98=>'cant_say', 0=>'No', 1=>'Yes'},
          2=>{-99=>'not_applicable', -98=>'cant_say', 0=>'No', 1=>'Partial', 2=>'Complete'}
      }

        db[:scales].insert(:id=>1, :name=>::I18n::t("scales.dichomotic"), :description=>::I18n::t('scales.dichotomic_description')) unless db[:scales][id:1]
        db[:scales].insert(:id=>2, :name=>::I18n::t("scales.three_values"), :description=>::I18n::t('scales.three_values_description'))  unless db[:scales][id:2]

      scales.each_pair do |scale_id, values|
        values.each_pair do |value, name|
          db[:scales_items].insert(scale_id:scale_id, value:value, name: ::I18n::t("scales.#{name}")) if db[:scales_items].where(scale_id:scale_id, value:value).count==0
        end
      end
    end
    def self.allocate_authorizations_to_roles(db)
      analyst_permits = ['review_view', 'review_analyze', 'message_view', 'message_edit', 'search_view', 'search_edit',
                         'record_view', 'record_edit', 'reference_view', 'reference_edit', 'file_view',
                         'canonical_document_view', 'group_view']
      analyst_permits.each do |auth|
        db[:authorizations_roles].replace(:authorization_id => auth, :role_id => 'analyst') if db[:authorizations_roles].where(:authorization_id => auth, :role_id => 'analyst').count==0
       end

      guest_permits = ['review_view', 'message_view', 'message_edit', 'search_view', 'record_view',
                       'reference_view', 'file_view', 'canonical_document_view', 'group_view']
      guest_permits.each do |auth|
        db[:authorizations_roles].replace(:authorization_id => auth, :role_id => 'guest') if db[:authorizations_roles].where(:authorization_id => auth, :role_id => 'guest').count==0
      end
    end

    def self.create_authorizations(db)
      authorizations = [
          'canonical_document_admin',
          'canonical_document_view',
          'crossref_query',
          'file_admin',
          'file_view',
          'group_admin',
          'group_view',
          'message_edit',
          'message_view',
          'pubmed_query',
          'record_edit',
          'record_view',
          'reference_edit',
          'reference_view',
          'reflection',
          'review_admin',
          'review_admin_view',
          'semantic_scholar_query',
          'review_analyze',
          'review_edit',
          'review_view',
          'role_admin',
          'role_view',
          'scale_admin',
          'institution_admin',
          'scopus_query',
          'search_edit',
          'search_view',
          'tag_edit',
          'user_admin'
      ]
      authorizations.each do |auth|
        db[:authorizations].insert(:id => auth) unless db[:authorizations][id:auth]
        #puts(db[:authorizations_roles].where(:authorization_id => auth, :role_id => 'administrator').count)
        db[:authorizations_roles].insert(:authorization_id => auth, :role_id => 'administrator') unless db[:authorizations_roles].where(:authorization_id => auth, :role_id => 'administrator').count>0
      end
    end

    def self.insert_group_user_if_not_exists(db, group_id, user_id)
      if db[:groups_users].where(:group_id => group_id, :user_id => user_id).count==0
        db[:groups_users].insert(:group_id => group_id, :user_id => user_id)
      end
    end
    def self.allocate_users_to_groups(db, id_admin, id_analyst, id_guest)
      if db[:groups][id:1]
        group_id = 1
      else
        group_id = db[:groups].insert(:id=>1,:group_administrator => id_admin, :description => "First group, just for demostration", :name => "demo group")
      end
      insert_group_user_if_not_exists(db,group_id, id_admin)
      insert_group_user_if_not_exists(db,group_id, id_analyst)
      if db[:groups][id:2]
        group_guest = 2
      else
        group_guest = db[:groups].insert(:id=>2,:group_administrator => id_admin, :description => "Guest group", :name => "guest group")
      end

      insert_group_user_if_not_exists(db,group_guest, id_admin)
      insert_group_user_if_not_exists(db,group_guest, id_guest)

    end

    # @!endgroup
  end
end