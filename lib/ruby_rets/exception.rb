module RubyRETS
	class Unauthorized < StandardError
		attr_reader :response
		def initialize(response)
		    @response = response
		  	super(response)
		end
	end
end