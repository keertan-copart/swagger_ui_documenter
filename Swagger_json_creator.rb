require 'rubygems'
require 'json'

class Service
  @@hotwords = %w[POST post get GET put PUT DELETE delete ]
  @@baseurl = ""
  @@all_tags = %w[]

  attr_reader :name, :tag, :comment, :paramset, :path, :name, :type, :status, :param_flag


  def intialize(default_name="post", type = 0, status = 1, param_flag = false, paramset = %w[], default_comment = "", tag = "/")
    @name = default_name
    @tag = tag
    @type = type
    @path = "/"
    @status = status
    @param_flag = param_flag
    @paramset = default_params
    @comment = default_comment
    @testing_lotno = 12345
  end

  def extract_service_from_line(line)
   	@name, @type = extract_name_and_type line
    @status = 1 #By default, assigning working status.
  end

  
  def extract_path_from_line(line)
    @path = line.scan(%r{'/.*/?'}).to_s.gsub(/'/,"")
  end

	def extract_name_and_type(line)
    if /(post|POST)\s(.*)/.match(line)
      ["post", 1]
    elsif /(get|GET)\s(.*)/.match(line)
      ["get", 2]
    elsif /(put|PUT)\s(.*)/.match(line) 
      ["put", 3]
    elsif /(delete|DELETE)\s(.*)/.match(line) 
      ["delete", 4]  
    end
	end

  def extract_params
    @tag = @path.scan(%r{/[a-zA-Z_]+})[0].to_s[1..-1]

    @paramset = @path.to_s.scan(%r{/:([a-zA-Z_]+)})
    unless @paramset.length==0
      @param_flag = true
    end
  end

  def format_path
		return unless @param_flag

		@paramset.each do |param|
			@path = @path.sub(/:#{param[0].to_s}/, "{"+param[0].to_s+"}")
		end
  end


  def self.baseurl=(url)
    @@baseurl = url
  end

  def self.all_tags=(given_all_tags)
    @@all_tags = given_all_tags
  end

  def self.push_tag(tag)
    @@all_tags.push(tag)
  end

  def self.baseurl
    @@baseurl
  end

  def self.all_tags
    @@all_tags
  end

  def comment=(extracted_comment)
    @comment = extracted_comment
  end

 
end


#Independent functions

def hotword?(line)
  !!/(post|POST|get|GET|DELETE|delete|put|PUT)\s(.*)/.match(line)
end


def commented?(line)
  temp = line.lstrip
  temp[0] == '#'? true : false
     
end


def tagger(tag)
  if !Service.all_tags.include? tag
    Service.all_tags.push(tag)
  end
end
#**********************************************************


# get service_handler file location, implementation using parameter pending...




# read line by line
count = 0
temp_comment = ""

if ARGV.empty?
  puts "Error: Specify file location as argument"
else
  Service.baseurl = "hello/sample" 

  services_array = Array.new
  
  temp_location = '/Users/kedakarapu/copart/ycs-api-transporter-app/ycs-api/app/handlers/transporter_handler.rb'  #Reading the file line by line
  File.readlines(ARGV[0].to_s).each do |line|
    if commented? line #check if its commented
      temp_comment += line
    elsif hotword? line
        s = Service.new
        s.extract_service_from_line line
        s.extract_path_from_line line
        s.extract_params
        s.format_path
        s.comment = (temp_comment + line[/[#](.)\1/].to_s)
        tagger s.tag
        services_array.push(s)
        s = nil
        count = count + 1
      end
  end
  
  puts count.to_s + " Routes Discovered"

end

#Generate json file

Service.all_tags.each do |tag|
  puts tag 
  services_array.each do |service_obj|
      if service_obj.tag == tag
        print "\t" + service_obj.path, service_obj.name + "\n"
      end
  end
end



=begin
  
  Documentation:


  Service
  Name :: Type
  post   1
  get    2
  put    3
  delete 4



=end


