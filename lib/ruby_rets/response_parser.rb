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
          @parsed = Parser::Compact.parse(body)
          @count = Parser::Compact.get_count(doc)
        elsif node = doc.at("//REData")
          @parsed = Parser::Xml.parse(body)
          @count = @body["Count"].to_i
        else
          @parsed = body
        end
      else
        self
      end
    end

    def parsed
      @parsed
    end

  end
end