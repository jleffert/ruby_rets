module RubyRETS
	class Unauthorized < StandardError
		attr_reader :response
		def initialize(response = "Authorization failed. Please check your username, password, and user agent.  If all are correct please wait a second and try again.  The servers sometimes reject/lose sessions for no reason.")
		    @response = response
		  	super(response)
		end
	end
end