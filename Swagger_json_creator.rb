require 'rubygems'
require 'json'



class Service
  @@baseurl = ""
  @@all_tags = %w[]

  attr_reader :name, :tag, :comment, :summary, :paramset, :path, :name, :type, :param_flag
  attr_accessor :deprecated

  def intialize(default_name="post", type = 0, path = "/", deprecated = false, param_flag = false, paramset = %w[], default_comment = "", default_summary = "Not provided")
    @name = default_name
    @tag = "/"
    @type = type
    @path = path
    @deprecated = deprecated
    @param_flag = param_flag
    @paramset = default_params
    @comment = default_comment
    @summary = default_summary
    @testing_lotno = 12345

    @@baseurl = "0.0.0.0:9292/transporter/"

  end

  def extraction line
    extract_service_from_line line
    extract_path_from_line line
    extract_params
    extract_tag
    format_path.to_s
  end

  def extract_service_from_line(line)
   	@name, @type = extract_name_and_type line
    @status = 1 #By default, assigning working status.
  end

  
  def extract_path_from_line(line)
    @path = line.scan(%r{'/.*/?'}).to_s.gsub!(/[\'\"\]\[]/, '')    
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
    @paramset = @path.to_s.scan(%r{/:([a-zA-Z_]+)})
    unless @paramset.length==0
      @param_flag = true
    end
  end

  def extract_tag
    @tag = @path.scan(%r{/[a-zA-Z_]+})[0].to_s[1..-1]
  end

  def format_path
		if @param_flag
		  @paramset.each do |param|
      @path = @path.sub(/:#{param[0].to_s}/, "{"+param[0].to_s+"}")
      end
    end
    @path
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

  def summary=(summary)
    @summary = summary
  end

  def comment=(extracted_comment)
    @comment = extracted_comment
  end

  
end
# end of class!

#Independent functions  ************************************

def extract_title url
  url.split('/').last.chomp('.rb') || "Unknown API"
end

def hotword? line
  /(post|POST|get|GET|DELETE|delete|put|PUT)\s(.*)/.match(line)
end


def single_commented? line
  temp = line.lstrip
  temp[0] == '#' && temp[1] != '#'? true : false
end

def double_commented? line
  temp = line.lstrip
  temp[0] == '#' && temp[1] == '#'? true : false
end

def format_comment line
  line.sub(/#/,"")
end

def format_internal_comment line
  format_comment line
end

def format_summary line
  line.scan(/#.+/)[0]&.sub('#','') || "Summary not provided"
end

def find_deprecated? line
  line.include?("-d") || line.include?("deprecated")
end

# check if a tag exists in our dictionary, if not it adds it and returns true. if yes, then it returns false.
def tagger(tag)
  if !Service.all_tags.include? tag
    Service.all_tags.push(tag)
    true
  else
    false
  end
end

def tag_array_creator tags
  tag_array = []
  tags.each { |tag| tag_array << { "name" =>  tag , "description" => ""} }
  tag_array
end

def generate_service_internal service_obj
  temp_hash = {}
  temp_hash["tags"] = [ service_obj.tag ]
  temp_hash["summary"] =  service_obj.summary
  temp_hash["description"] = service_obj.comment
  temp_hash["consumes"] = %w[ application/json application/xml]
  temp_hash["produces"] = %w[ application/json application/xml]
  temp_hash["deprecated"] = service_obj.deprecated ? true : false
  temp_hash
end

def generate_path_internal services 
  temp_hash = {}
  services.each do |service_obj_loc| 
    service_obj = $services_array[service_obj_loc]
    temp_hash["#{service_obj.name}"] = generate_service_internal service_obj
  end
  temp_hash
end

def generate_internal tag_and_path_based_service_order
  paths_internal_json = {}
  tag_and_path_based_service_order.each do |_tag, path_array| 
    path_array.each { |path, services_array| paths_internal_json["#{path}"] = generate_path_internal services_array } 
  end
  paths_internal_json
end

def create_json(title, host = "127.0.0.1", basepath = "/", tag_and_path_based_service_order)
  js = 
    { 
      "swagger": "2.0",
      "info": {
              "description": "",
              "version": "1.0.0",
              "title": title,
              "termsOfService": "http://swagger.io/terms/",
              "license": {
                  "name": "Apache 2.0",
                  "url": "http://www.apache.org/licenses/LICENSE-2.0.html"
                  }
              }
    }

  js["host"] = host
  js["basePath"] = basepath
  js["tags"] = tag_array_creator Service.all_tags
  js["schemes"] = %w[ http ]
  js["paths"] = generate_internal(tag_and_path_based_service_order)
  js.to_json
end

#**********************************************************

if ARGV.empty?
  puts "Error: Specify file location as argument"
else
  Service.baseurl = "hello/sample"
  service_count = 0
  comment_accumulator = ""
  tag_and_path_based_service_order = {}
  $services_array = Array.new # Declare a global array for handling services objects created

  temp_location = '/Users/kedakarapu/copart/ycs-api-transporter-app/ycs-api/app/handlers/transporter_handler.rb'  #Reading the file line by line
  ARGV[0] ||= temp_location #for testing, considering a hard coded path
  title = extract_title ARGV[0] 

  # read line by line

  File.readlines(ARGV[0].to_s).each do |line|
    if single_commented? line #check if its commented
      comment_accumulator += format_comment line
    elsif hotword? line
      s = Service.new
      service_count = service_count + 1
      s.extraction line      
      s.comment = comment_accumulator
      s.summary = format_summary line
      s.deprecated = find_deprecated? s.summary
      comment_accumulator = ""
      $services_array.push(s)
      
      #format into order of json creation.
      
      if tagger(s.tag) #returns false if tag already exists
        tag_and_path_based_service_order[s.tag] = { s.path => [ service_count-1 ] }
      else
        #check if the path exists. If yes, add (service_count-1) to it, if not create one and add.
        if tag_and_path_based_service_order.has_key?(s.tag) && tag_and_path_based_service_order[s.tag].has_key?(s.path) 
          tag_and_path_based_service_order[s.tag][s.path] << (service_count - 1)
        else
          tag_and_path_based_service_order[s.tag][s.path] = [ service_count-1 ]
        end
      end
      s = nil
    elsif double_commented? line
      $services_array[service_count-1].comment += format_internal_comment line
    end
  end  
end

puts service_count.to_s + " Routes Discovered"

#Generate json file
puts create_json(title, tag_and_path_based_service_order)




