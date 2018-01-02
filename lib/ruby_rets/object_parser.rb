require 'mechanize'

module RubyRETS
  class ObjectParser < Mechanize::File
    include Mechanize::Parser

    def initialize(uri = nil, response = nil, body = nil, code = nil)
      super(uri, response, body, code)
      _b = header['content-type'].split(";")[1].strip
      if _match = /boundary=(.*)/.match(_b)
        @boundary = _match[1]
      else
        @boundary = _b
      end
        @boundary = @boundary.gsub "\"", ''

      @objects = []
      division = body.split("\r\n--#{@boundary}")
      division.shift if division.first.strip == ""
      division.pop if division.last.strip == "--"
      division.each do |object|
        parts = object.split("\r\n\r\n")
        headers = parse_object_header(parts[0])
        file_obj = File.new(File.join(Dir::tmpdir, "#{headers['Content-ID']}_#{headers['Object-ID']}_#{Time.now.to_i.to_s}"), 'w+b') << parts[1]
        file_obj.close
        @objects << {:headers => headers, :data => file_obj} unless parts[1].nil?
      end

      @parsed = @objects
    end

    def parsed
      @parsed
    end

    private
    def parse_object_header(string)
      Hash[string.split("\r\n").delete_if {|pair| pair.empty?}.map {|pair| pair.split(":").map {|item| item.strip}}]
    end

    def preferred_extension_from_mime(mime_type)
      type = MIME::Types[mime_type]
      unless type.nil?
        if type.first.extensions.count == 1
          type.first.extensions.first
        else
          possible = type.first.extensions
          possible.delete_if {|ext| ext.length > 3}
          possible.first
        end
      else
        "ukn"
      end
    end
  end
end