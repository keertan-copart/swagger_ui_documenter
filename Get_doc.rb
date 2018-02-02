

class Ycs::Get_doc
	attr_reader :trial

	def initialize
		@trial = "hello"
	end

end 



gg = Get_doc.new
puts gg.trial