module Scopus
  module XMLResponse
    class Abstractsretrievalresponse < XMLResponseGeneric
      NA_AFFILIATION="NAFD:**NA**"
      NA_AFFILIATION_NAME="__No affiliation__"
      attr_reader :scopus_id
      attr_reader :cited_by_count
      attr_reader :title
      attr_reader :eid
	attr_reader :type_code
      attr_reader :type
      attr_reader :year
      attr_reader :journal
      attr_reader :authors
      attr_reader :volume
      attr_reader :issue
      attr_reader :starting_page
      attr_reader :ending_page
      attr_reader :doi
      attr_reader :affiliations
      attr_reader :abstract
      attr_reader :subject_areas
      attr_reader :author_keywords
      attr_reader :book_title
      attr_reader :author_groups
      def inspect
        "#<#{self.class}:#{self.object_id} @title=#{@title} @journal=#{@journal} @authors=[#{@authors.keys.join(",")}]>"
      end
      def process

        @authors={}
        @affiliations={}
        @author_keywords=[]
        @subject_areas=[]
        @author_groups=[]
        process_basic_metadata
        process_taxonomy
        process_affiliations
        process_author_groups
        process_authors
      end


      # We can't find the affiliation the ussual way
      # we have to improvise
      # Given the afid, we search on every <affiliation> tag until
      # we find the desired one
      def search_affiliation(afid)
        x=xml.at_xpath("//affiliation[@afid=\"#{afid}\"]")
        if !x
          raise "I can't find affiliation #{afid}"
        else
          name=x.xpath("organization").map { |e| e.text }.join(";")
          city=process_path(xml, "//affiliation[@afid=\"#{afid}\"]/city-group")
          country=process_path(xml, "//affiliation[@afid=\"#{afid}\"]/country")
          country||=x.attribute("country").value
        end
        {:id => afid, :name => name, :city => city, :country => country,:type=>:scopus}
      end

      # We have to find doi on
      def search_doi
        if xml.at_xpath("//source").text=~/^\s*http:\/\/dx\.doi\.org\/([^\s]+)/
          return $1

        end
      end

      def get_affiliation_id(aff)
        if aff.nil?
          nil
        elsif id=aff.attribute('afid')
          id.value
        else
          city, country, id, name = get_affiliation_data(aff)
          id
        end
      end

      def search_affiliation_country(id)
        return nil if id.nil?
        process_path(xml, "//affiliation[@afid='#{id}']/country")
      end
      def process_affiliations
        xml.xpath("/xmlns:abstracts-retrieval-response/xmlns:affiliation").each do |x|
          id=x.attribute("id").value
          next if id==""
          name=process_path(x, "xmlns:affilname")
          city=process_path(x, "xmlns:affiliation-city")
          country=process_path(x, "xmlns:affiliation-country")
          country=search_affiliation_country(id) if (country=="")
          @affiliations[id]={
              :id => id,
              :name => name,
              :city => city,
              :country => country,
              :type=>:scopus
          }
        end
        add_unidentified_affilitations
      end

      # Some affiliations doesn't have an id. We could create it
      # hashing the name and the country on unidentified filliations on 
      # head tag
      # The process only add the affiliation if name is not nil
      
      def get_id_affiliation(name,city,country)
      "NS:"+Digest::MD5.hexdigest("#{name}|#{city}|#{country}")
      end
      def add_unidentified_affilitations
        xml.xpath("//bibrecord/head/author-group/affiliation").each do |aff|
          next if aff.attribute("afid")
          city, country, id, name = get_affiliation_data(aff)
          next if (name=="" and city=="" and country=="")


          @affiliations[id]={
              :id => id,
              :name => name,
              :city => city,
              :country => country,
              :type=>:non_scopus
          }
        end
      end
      def add_no_affiliation_case(auid)
        id=NA_AFFILIATION+":"+Digest::MD5.hexdigest("#{@scopus_id}|#{auid}")
        @affiliations[id]={
              :id => id,
              :name => "#{@scopus_id}|#{auid}",
              :city => "",
              :country => "NO_COUNTRY",
              :type=>:non_scopus
          }
          id
      end
      def get_affiliation_data(aff)
        organization=aff.xpath("organization").map { |e| e.text }.join(";")
        address=aff.xpath("address-part").map { |e| e.text }.join(";")
        name= organization!="" ? organization : address
        city_only=aff.xpath("city").text
        city_part=aff.xpath("city-group").text
        city= city_only!="" ? city_only : city_part
        country=aff.xpath("country").text

        name="UNKOWN ORG FOR #{@scopus_id} ARTICLE" if name==""
        country="NO_COUNTRY" if country==""


        id=get_id_affiliation(name,city,country)
        return city, country, id, name
      end

      # Author groups gives us information about the authors
      # groups as appears on the head. Could be useful to retrieve
      # information about missing affilitations
      # Author-groups with authors duplicated are eliminated
      def process_author_groups
        author_groups_temp=xml.xpath("//bibrecord/head/author-group").map do |ag|
            if aff_node=ag.at_xpath("affiliation")
              city,country,afid1,name=get_affiliation_data(aff_node)
              aff_id2=get_affiliation_id(ag.at_xpath("affiliation"))
              if (name=="" and city=="" and country=="")
                aff_id=nil
              else
                aff_id=aff_id2
              end
            else
              aff_id=nil
            end
          {:authors=>ag.xpath("author").map {|auth|
            a=auth.attribute('auid')
            a ? a.value : nil},
           :affiliation=>aff_id
          }
        end

        authors_list= []
        @author_groups=author_groups_temp
#        @author_groups=[]
#        author_groups_temp.each do |ag|
#          @author_groups.push(ag) unless ag[:authors].any? {|author| authors_list.include? author}
#          authors_list=authors_list | ag[:authors]
#        end

      end



      def process_authors
        xml.xpath("//xmlns:authors/xmlns:author").each do |x|
          auid=x.attribute("auid").value
          seq=x.attribute("seq").value
          initials =process_path(x, "xmlns:preferred-name/ce:initials")
          indexed_name = process_path(x, "xmlns:preferred-name/ce:indexed-name")
          given_name =process_path(x, "xmlns:preferred-name/ce:given-name")
          surname=process_path(x, "xmlns:preferred-name/ce:surname")
          affiliation=nil
          affiliation_node=x.xpath("xmlns:affiliation")
          
          if affiliation_node.length==1
            affiliation=affiliation_node[0].attribute("id").text
            if !affiliation.nil? and @affiliations[affiliation].nil?
              @affiliations[affiliation]=search_affiliation(affiliation)
            end
          elsif affiliation_node.length>1
            affiliation=affiliation_node.map{|af| 
              af.attribute("id").text
            }.uniq
            affiliation.each do |af|
              if !af.nil? and @affiliations[af].nil?
                @affiliations[af]=search_affiliation(af)
              end
            end 
          else
            # Must search in author-groups for affilitation
            res=@author_groups.find{|ag|
              ag[:authors].include? auid
            }
            
            if res
              affiliation=res[:affiliation]
            end
            if affiliation.nil?
              # Affiliation shouldn't be nil. We create a custom affiliation for this cases
              affiliation=add_no_affiliation_case(auid)
            end

            #
          end

          #p "#{nombre} #{apellido}"
          @authors[auid]={
              :auid => auid,
              :seq => seq,
              :initials => initials,
              :indexed_name => indexed_name,
              :given_name => given_name,
              :surname => surname,
              :email => nil,
              :affiliation => affiliation
          }


        end
        # Searching for authors e-mails

        xml.xpath("//bibrecord//head//author-group/author//ce:e-address[@type='email']").each do |email|
          auid=email.parent.attribute("auid").value
          @authors[auid][:email]=email.text
        end
      end


      def process_taxonomy
        xml.xpath("//xmlns:authkeywords/xmlns:author-keyword").each do |x|
          @author_keywords.push(x.text)
        end
        xml.xpath("//xmlns:subject-areas/xmlns:subject-area").each do |x|
          @subject_areas.push(
              {:abbrev => x.attribute("abbrev").value,
               :code => x.attribute("code").value.to_i,
               :name => x.text
              }
          )
        end
      end

      def process_basic_metadata
        @scopus_id      = process_path(xml, "//dc:identifier")
        @title          = process_path(xml, "//dc:title")
        @doi            = process_path(xml, "//prism:doi")
        @doi||=search_doi
        @eid		= process_path(xml, "//xmlns:eid")
	@type_code      = process_path(xml, "//xmlns:srctype")
        @cited_by_count = process_path(xml,"//xmlns:citedby-count").to_i
        @type           = process_path(xml, "//prism:aggregationType").downcase.to_sym
        if @type_code=="j" or @type_code=="p"
          @journal      =process_path(xml, "//prism:publicationName")
          @volume       =process_path(xml, "//prism:volume")
          @issue        =process_path(xml, "//prism:issueIdentifier")
        elsif @type_code=="b"
          @book_title   =process_path(xml, "//prism:publicationName")
        end
        @starting_page  =process_path(xml, "//prism:startingPage")
        @ending_page    =process_path(xml, "//prism:endingPage")
        @year           =process_path(xml, "//year")
        @abstract       =process_path(xml, "//dc:description/xmlns:abstract[@xml:lang='eng']/ce:para")
	@abstract     ||=process_path(xml, "//abstract/ce:para")
      end
    end
  end
end
