require 'mechanize'
require 'pry'

module RETS
  @parsed_hash = {}
  NUMBERS_TO_NAME = {             
    12=>"Twelve",
    11 => "Eleven",
    10 => "Ten",
    9 => "Nin",
    8 => "Eigh",
    7 => "Seven",
    6 => "Six",
    5 => "fif",
    4 => "Four",
    3 => "Thi",
    2 => "Seco",
    1 => "Fir"
  }

  OBJECT_CLASS_TAGS = ['Residential', 'CommercialSale', 'Land', 'Member']
  OBJECT_TAGS = ['Property', 'Member']

  def self.login
    @conn = Mechanize.new
    @conn.add_auth("http://rets172lax.raprets.com:6103/Midlands/MIDL/login.aspx", ENV["RETS_USER_ID"], ENV["RETS_PASSWORD"])
    @conn.user_agent = ENV["RETS_USER_AGENT"]
    @conn.request_headers = { "RETS-Version" => "RETS/1.7.2" }

   begin
      @conn.post("http://rets172lax.raprets.com:6103/Midlands/MIDL/login.aspx")
    rescue Mechanize::UnauthorizedError
      RETS::Unauthorized.new
    rescue => e
     @exception = e
   end
  end

  def self.logout
    begin
      @conn.post("http://rets172lax.raprets.com:6103/Midlands/MIDL/logout.aspx")
    rescue => e
      @exception = e
    end
  end

  def self.metadata_system
    query = {
      "type" => "METADATA-RESOURCE",
      "format" => "STANDARD-XML",
      "ID" => 0
    }
    begin
      response = @conn.post("http://rets172lax.raprets.com:6103/Midlands/MIDL/getmetadata.aspx", query)
    rescue => e
      @exception = e
    end

    response.xml.xpath('//Resource').each do |node|
      puts "NEW RESOURCE"
      node.children.each do |child_node|
        puts "#{child_node.name}: #{child_node.child}"
      end
    end
  end

  def self.class_metadata(resource_id = 0)
      query = {
        "type" => "METADATA-CLASS",
        "format" => "STANDARD-XML",
        "ID" => resource_id
      }

      begin
        response = @conn.post("http://rets172lax.raprets.com:6103/Midlands/MIDL/getmetadata.aspx", query)
      rescue => e
        @exception = e
      end

      response.xml.xpath('//Class').each do |node|
        puts "NEW CLASS"
        node.children.each do |child_node|
          puts "#{child_node.name}: #{child_node.child}"
        end
      end
  end

  def self.table_metadata(resource_id, class_name = '')
      resource_id = "#{resource_id}:class_name" if !class_name.empty?

      query = {
        "type" => "METADATA-TABLE",
        "format" => "STANDARD-XML",
        "ID" => (resource_id)
      }

      begin
        response = @conn.post("http://rets172lax.raprets.com:6103/Midlands/MIDL/getmetadata.aspx", query)
      rescue => e
        @exception = e
      end

      response.xml.xpath('//Field').each do |node|
        puts "NEW TABLE VALUE"
        node.children.each do |child_node|
          puts "#{child_node.name}: #{child_node.child}"
        end
      end
  end

  def self.search(query_string = nil)
    query = {
      # "SearchType" => "Agent",
      "SearchType" => "Property",
      #Residential
      # "Class" => "MEMB",
      "Class" => "LOTL",
      #RETS requires queries use the lookup operator (=|) when using searching on codes of a lookup field.
      "Query" => "(City=|Lincoln),(Status=|A)",
      # "Query" => "(City=Lincoln)",(Status=|A)
      #Query Language
      "QueryType" => "DMQL2",
      "Format" => "STANDARD-XML",
      # "Limit" => "1",
      "Count" => "1",
      "StandardNames" => "0"
    }
    begin
      @conn.post("http://rets172lax.raprets.com:6103/Midlands/MIDL/search.aspx", query)
    rescue => e
      @exception = e
    end
  end

  module Parser
    @current_object = ""
    @current_class = ""
    @object_hash = {}

    def self.fixXml(body)
      # Replace tags starting with numbers with text
      body.gsub(/.*\<(\d).*\>.*\<\/(\1).*>.*/) do |broken_xml|
        broken_xml.gsub($1, RETS::NUMBERS_TO_NAME[$1.to_i])
      end
    end

    def self.parseXML(xml, field)
        @parsed_hash = {}
        @current_object = ""
        @current_class = ""
        count = xml.xpath("/RETS/COUNT").first.attributes["Records"].value
        @parsed_hash.merge!({ "Count" => count })

        xml.xpath("//#{field}").children.each do |node|
          
          if OBJECT_CLASS_TAGS.include? node.name
            @current_class = node.name
            @parsed_hash[node.name] = {}
            parse_children(node)
            @parsed_hash[@current_class][@current_object] << @object_hash
          end
        end

        @parsed_hash
    end

    def self.parse_children(node)
      node.children.each do |child_node|   
        if (child_node.children.any?)
          if child_node.children.length == 1 and child_node.child.text?
              @object_hash[child_node.name] = child_node.child.content
          elsif OBJECT_TAGS.include? child_node.name
            @current_object = child_node.name
            if @parsed_hash[@current_class][@current_object].nil?
              @parsed_hash[@current_class][@current_object] = []
            else
              @parsed_hash[@current_class][@current_object] << @object_hash
            end
            @object_hash = {}
            parse_children(child_node)
          else
            parse_children(child_node)
          end
        end
      end
    end
  end

  class Unauthorized
      attr_reader :error_message
      def initialize
        @error_message = "Authorization failed. Please check your username, password, and user agent.  If all are correct please wait a second and try again.  The servers sometimes reject/lose sessions for no reason."
      end
  end
end

@response = RETS.login

unless @response == RETS::Unauthorized
  @results = RETS.search

  if @results == Mechanize::ResponseCodeError
    puts "I should make a custome error for this too but I will in the actual library"
    puts @results.page.xml.xpath('//RETS')[0].attributes["ReplyText"].value
  else 
    @parsed_string = RETS::Parser.fixXml(@results.body)
    @parsed_xml = Nokogiri::XML(@parsed_string)
    @parsed_hash = RETS::Parser.parseXML(@parsed_xml, '/REData/REProperties') #/REProperties
    puts @parsed_hash
  end
else 
  puts "Unauthorized"
  puts @response.inspect
end