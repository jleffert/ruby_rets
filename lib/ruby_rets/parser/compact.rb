require 'nokogiri'

module RubyRETS
  module Parser
    class Compact
      DEFAULT_DELIMITER = "\t"

      def self.parse(xml)
        document = SaxParser.new
        # Seperate DELIMITER, COLUMNS, and DATA
        parser = Nokogiri::XML::SAX::Parser.new(document)
        io = StringIO.new(xml.to_s)

        parser.parse(io)
        delimiter = document.delimiter || DEFAULT_DELIMITER
        delimiter = Regexp.new(Regexp.escape(delimiter))
        column_names = document.columns.split(delimiter)
        document.results.map {|data| parse_object(column_names, data, delimiter) }
      end

      class SaxParser < Nokogiri::XML::SAX::Document
        attr_reader :results, :columns, :delimiter

        def initialize
          @results = []
          @columns = ''
          @result_index = nil
          @delimiter = nil
          @columns_start = false
          @data_start = false
        end

        def start_element(name, attrs=[])
          case name
          when 'DELIMITER'
            @delimiter = attrs.last.last.to_i.chr
          when 'COLUMNS'
            @columns_start = true
          when 'DATA'
            @result_index = @results.size
          end
        end

        def end_element(name)
          case name
          when 'COLUMNS'
            @columns_start = false
          when 'DATA'
            @result_index = nil
          end
        end

        def characters(string)
          if @columns_start
            @columns << string
          end

          if @result_index
            @results[@result_index] ||= ''
            @results[@result_index] << string
          end
        end
      end

      def self.parse_object(column_names, data, delimiter)
        data_values = data.split(delimiter, -1)
        zipped_key_values = column_names.zip(data_values).map { |k, v| [k, v.to_s] }

        hash = Hash[*zipped_key_values.flatten]
        hash.reject { |key, value| key.empty? && value.to_s.empty? }
      end

      def self.get_count(xml)
        doc = Nokogiri.parse(xml.to_s)
        if node = doc.at("//COUNT")
          node.attr('Records').to_i
        else
          0
        end
      end
    end
  end
end