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

    private
    def conn
      @conn ||= create_connection
    end

    def create_connection
      @conn = Mechanize.new
      @conn.user_agent = @user_agent
      @conn.request_headers = @request_headers
      @conn.add_auth(@host_login, @auth[:username], @auth[:password])
      @conn
    end
  end
end