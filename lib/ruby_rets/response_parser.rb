require 'mechanize'

module RubyRETS
  class ResponseParser < Mechanize::File
    include Mechanize::Parser

    OBJECT_CLASS_TAGS = ['Residential', 'CommercialSale', 'Land', 'Member']
    OBJECT_TAGS = ['Property', 'Member']

    def initialize(uri = nil, response = nil, body = nil, code = nil)
      super(uri, response, body, code)
      if !body.empty? and body.include? "<REData>"
        @body = parse_response(body)
      else
        self
      end
    end

    def parsed
      @body
    end

    private
    def parse_response(body)
      body = fix_xml_tag_names(body)
      parse_xml(Nokogiri::XML(body))
    end

    def fix_xml_tag_names(body)
      # Remove extra space between XML elements
      body.gsub!(/>\s*</) do |match| 
        match.gsub(/\s*/,'')
      end
    end

    def parse_xml(xml, parsed_hash = {})
      count = xml.xpath("/RETS/COUNT").first.attributes["Records"].value
      parsed_hash.merge!({ "Count" => count })

      xml.xpath("//REData/REProperties").children.each do |node|
        if OBJECT_CLASS_TAGS.include? node.name
          current_class = node.name
          parsed_hash[current_class] = {}
          node.children.each do |child_node|
            if OBJECT_TAGS.include? child_node.name
              if parsed_hash[current_class][child_node.name].nil?
                parsed_hash[current_class][child_node.name] = []
              end
              object_hash = parse_object(child_node, current_class)
              parsed_hash[current_class][child_node.name] << object_hash 
            end
          end
        end
      end

      parsed_hash
    end

    def parse_object(node, current_class, object_hash = {})
      node.children.each do |child_node|
        if child_node.children.length == 1 and child_node.child.text?
           object_hash[child_node.name] = child_node.child.content
        elsif child_node.children.any?
          object_hash[child_node.name] = parse_nested_attribute(child_node)
        else
          object_hash[child_node.name] = ""
        end
      end

      object_hash
    end

    def parse_nested_attribute(node, attribute_hash = {})
      node.children.each do |child_node|
        if child_node.children.length == 1 and child_node.child.text?
          attribute_hash[child_node.name] = child_node.child.content
        elsif child_node.children.any?
          attribute_hash[child_node.name] = parse_nested_attribute(child_node)
        else
          attribute_hash[child_node.name] = ""
        end
      end

      attribute_hash
    end
  end
end