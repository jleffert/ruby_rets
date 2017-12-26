require 'mechanize'

module RubyRETS
  class ResponseParser < Mechanize::File
    include Mechanize::Parser

    OBJECT_CLASS_TAGS = ['Residential', 'CommercialSale', 'Land', 'Member']
    OBJECT_TAGS = ['Property', 'Member']
    @parsed_hash = {}
    @current_object = ""
    @current_class = ""

    def initialize(uri = nil, response = nil, body = nil, code = nil)
      super(uri, response, body, code)
      if !body.empty? and body.include? "<REData>"
        parse_response(body)
      else
        self
      end
    end
    private
    def parse_response(body)
      xml = fix_xml_tag_names(body)
      @body = Nokogiri::XML(xml)
    end

    def fix_xml_tag_names(body)
      # Replace tags starting with numbers with text
      body.gsub(/.*\<(\d).*\>.*\<\/(\1).*>.*/) do |broken_xml|
        broken_xml.gsub($1, RETS::NUMBERS_TO_NAME[$1.to_i])
      end
    end
  end
end