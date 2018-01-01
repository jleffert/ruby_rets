require 'mechanize'

module RubyRETS
  class ResponseParser < Mechanize::File
    include Mechanize::Parser
    attr_reader :count

    def initialize(uri = nil, response = nil, body = nil, code = nil)
      super(uri, response, body, code)
      if !body.empty?
        doc = Nokogiri.parse(body.to_s)
        if node = doc.at("//DELIMITER")
          @body = Parser::Compact.parse(body)
          @count = Parser::Compact.get_count(doc)
        elsif node = doc.at("//REData")
          @body = Parser::Xml.parse(body)
          @count = @body["Count"].to_i
        else
          @body = body
        end
      else
        self
      end
    end

    def parsed
      @body
    end

  end
end