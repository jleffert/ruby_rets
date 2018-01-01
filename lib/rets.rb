module RubyRETS
  class RETS
    RETS_VERSION = "RETS/1.7.2".freeze

    def initialize(username, password, user_agent, host_login)
      @auth = { username: username.to_s, password: password.to_s }
      @user_agent = user_agent
      @host_login = host_login
      @request_headers = { "RETS-Version" => RETS_VERSION }
    end

    def post(uri, query = {}, headers = {})
      begin
        conn.post(uri, query, headers)
      rescue Mechanize::UnauthorizedError
        raise RubyRETS::Unauthorized.new()
      rescue => e
        @exception = e
      end
    end

    def login(login_url)
      self.post("#{@host_login}#{login_url}")
    end

    def logout(logout_url)
      self.post("#{@host_login}#{logout_url}")
    end

    def search(resource, resource_class, query_string, search_url, options = {})
      options[:limit] ||= "NONE"
      options[:offset] ||= "0"
      query = {
        "SearchType" => resource,
        "Class" => resource_class,
        "Query" => query_string,
        "Select" => options.fetch(:select, nil),
        "QueryType" => options.fetch(:query_type, "DMQL2"),
        "Format" => options.fetch(:format, "COMPACT"),
        "Offset" => options[:offset],
        "Limit" => options[:limit],
        "Count" => options.fetch(:count, 1),
        "StandardNames" => options.fetch(:standard_names, 1)
      }.reject { |x,y| y.nil? }

      self.post("#{@host_login}#{search_url}", query)
    end

    private
    def conn
      @conn ||= create_connection
    end

    def create_connection
      @conn = Mechanize.new
      @conn.user_agent = @user_agent
      @conn.request_headers = @request_headers
      @conn.add_auth(@host_login, @auth[:username], @auth[:password])
      @conn.pluggable_parser.xml = RubyRETS::ResponseParser
      @conn
    end
  end
end