require 'mechanize'

module RubyRETS
  class ResponseParser < Mechanize::File
    include Mechanize::Parser

    OBJECT_CLASS_TAGS = ['Residential', 'CommercialSale', 'Land', 'Member']
    OBJECT_TAGS = ['Property', 'Member']

    def initialize(uri = nil, response = nil, body = nil, code = nil)
      super(uri, response, body, code)
      if !body.empty? and body.include? "<REData>"
        @body = {}
        @object_hash = {}
        parse_response(body)
      else
        self
      end
    end

    def parse
      @body
    end

    private
    def parse_response(body)
      body = fix_xml_tag_names(body)
      xml = Nokogiri::XML(body)
      parse_xml(xml)
    end

    def fix_xml_tag_names(body)
      # Replace tags starting with numbers with text
      body.gsub(/.*\<(\d).*\>.*\<\/(\1).*>.*/) do |broken_xml|
        broken_xml.gsub($1, RETS::NUMBERS_TO_NAME[$1.to_i])
      end
    end

    def parse_xml(xml)
      count = xml.xpath("/RETS/COUNT").first.attributes["Records"].value
      @body.merge!({ "Count" => count })

      xml.xpath("//REData/REProperties").children.each do |node|
        if OBJECT_CLASS_TAGS.include? node.name
          current_class = node.name
          @body[current_class] = {}
          node.children.each do |child_node|
            if OBJECT_TAGS.include? child_node.name
              set_new_object(child_node.name, current_class)
              parse_object(child_node, current_class)
              @body[current_class][@current_object] << @object_hash
            end
          end
        end
      end
    end

    def parse_object(node, current_class, depth = "")
      *keys, last = depth.split(".")
      node.children.each do |child_node|
        if child_node.children.length == 1 and child_node.child.text?
          set_key_value(keys, last, child_node.name, child_node.child.content)
        elsif child_node.children.any?
          set_key_value(keys, last, child_node.name, {})
          parse_object(child_node, current_class, "#{depth + '.' if !depth.empty?}#{child_node.name}")
        end
      end
    end

    def set_key_value(keys, last, new_name, content)
      if last.nil?
        @object_hash[new_name] = content
      else
        keys.inject(@object_hash, :fetch)[last][new_name] = content
      end
    end

    def set_new_object(object_name, current_class)
      @current_object = object_name
      if @body[current_class][@current_object].nil?
        @body[current_class][@current_object] = []
      else
        @body[current_class][@current_object] << @object_hash
      end
      @object_hash = {}
    end
  end
end